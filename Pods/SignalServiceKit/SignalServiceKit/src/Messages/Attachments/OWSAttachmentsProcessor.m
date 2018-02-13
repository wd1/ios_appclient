//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSAttachmentsProcessor.h"
#import "Cryptography.h"
#import "MIMETypeUtil.h"
#import "NSNotificationCenter+OWS.h"
#import "OWSError.h"
#import "OWSSignalServiceProtos.pb.h"
#import "TSAttachmentPointer.h"
#import "TSAttachmentRequest.h"
#import "TSAttachmentStream.h"
#import "TSGroupModel.h"
#import "TSGroupThread.h"
#import "TSInfoMessage.h"
#import "TSMessage.h"
#import "TSNetworkManager.h"
#import "TSStorageManager.h"
#import "TSThread.h"
#import <YapDatabase/YapDatabaseConnection.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const kAttachmentDownloadProgressNotification = @"kAttachmentDownloadProgressNotification";
NSString *const kAttachmentDownloadProgressKey = @"kAttachmentDownloadProgressKey";
NSString *const kAttachmentDownloadAttachmentIDKey = @"kAttachmentDownloadAttachmentIDKey";

// Use a slightly non-zero value to ensure that the progress
// indicator shows up as quickly as possible.
static const CGFloat kAttachmentDownloadProgressTheta = 0.001f;

@interface OWSAttachmentsProcessor ()

@property (nonatomic, readonly) TSNetworkManager *networkManager;
@property (nonatomic, readonly) TSStorageManager *storageManager;
@property (nonatomic, readonly) NSArray<TSAttachmentPointer *> *supportedAttachmentPointers;

@end

@implementation OWSAttachmentsProcessor

- (instancetype)initWithAttachmentPointer:(TSAttachmentPointer *)attachmentPointer
                           networkManager:(TSNetworkManager *)networkManager
                           storageManager:(TSStorageManager *)storageManager
{
    self = [super init];
    if (!self) {
        return self;
    }

    _networkManager = networkManager;
    _storageManager = storageManager;

    _supportedAttachmentPointers = @[ attachmentPointer ];
    _supportedAttachmentIds = @[ attachmentPointer.uniqueId ];

    return self;
}

- (instancetype)initWithAttachmentProtos:(NSArray<OWSSignalServiceProtosAttachmentPointer *> *)attachmentProtos
                               timestamp:(uint64_t)timestamp
                                   relay:(nullable NSString *)relay
                                  thread:(TSThread *)thread
                          networkManager:(TSNetworkManager *)networkManager
                          storageManager:(TSStorageManager *)storageManager
                             transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    self = [super init];
    if (!self) {
        return self;
    }

    _networkManager = networkManager;
    _storageManager = storageManager;

    NSMutableArray<NSString *> *attachmentIds = [NSMutableArray new];
    NSMutableArray<TSAttachmentPointer *> *supportedAttachmentPointers = [NSMutableArray new];
    NSMutableArray<NSString *> *supportedAttachmentIds = [NSMutableArray new];

    for (OWSSignalServiceProtosAttachmentPointer *attachmentProto in attachmentProtos) {

        OWSAssert(attachmentProto.id != 0);
        OWSAssert(attachmentProto.key != nil);
        OWSAssert(attachmentProto.contentType != nil);

        // digest will be empty for old clients.
        NSData *digest = attachmentProto.hasDigest ? attachmentProto.digest : nil;

        TSAttachmentType attachmentType = TSAttachmentTypeDefault;
        if ([attachmentProto hasFlags]) {
            UInt32 flags = attachmentProto.flags;
            if ((flags & (UInt32)OWSSignalServiceProtosAttachmentPointerFlagsVoiceMessage) > 0) {
                attachmentType = TSAttachmentTypeVoiceMessage;
            }
        }

        TSAttachmentPointer *pointer = [[TSAttachmentPointer alloc] initWithServerId:attachmentProto.id
                                                                                 key:attachmentProto.key
                                                                              digest:digest
                                                                           byteCount:attachmentProto.size
                                                                         contentType:attachmentProto.contentType
                                                                               relay:relay
                                                                      sourceFilename:attachmentProto.fileName
                                                                      attachmentType:attachmentType];

        [attachmentIds addObject:pointer.uniqueId];

        [pointer saveWithTransaction:transaction];
        [supportedAttachmentPointers addObject:pointer];
        [supportedAttachmentIds addObject:pointer.uniqueId];
    }

    _attachmentIds = [attachmentIds copy];
    _supportedAttachmentPointers = [supportedAttachmentPointers copy];
    _supportedAttachmentIds = [supportedAttachmentIds copy];

    return self;
}

- (void)fetchAttachmentsForMessage:(nullable TSMessage *)message
                    storageManager:(TSStorageManager *)storageManager
                           success:(void (^)(TSAttachmentStream *attachmentStream))successHandler
                           failure:(void (^)(NSError *error))failureHandler
{
    [[storageManager newDatabaseConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self fetchAttachmentsForMessage:message
                             transaction:transaction
                                 success:successHandler
                                 failure:failureHandler];
    }];
}

- (void)fetchAttachmentsForMessage:(nullable TSMessage *)message
                       transaction:(YapDatabaseReadWriteTransaction *)transaction
                           success:(void (^)(TSAttachmentStream *attachmentStream))successHandler
                           failure:(void (^)(NSError *error))failureHandler
{
    OWSAssert(transaction);

    for (TSAttachmentPointer *attachmentPointer in self.supportedAttachmentPointers) {
        [self retrieveAttachment:attachmentPointer
                         message:message
                     transaction:transaction
                         success:successHandler
                         failure:failureHandler];
    }
}

- (void)retrieveAttachment:(TSAttachmentPointer *)attachment
                   message:(nullable TSMessage *)message
               transaction:(YapDatabaseReadWriteTransaction *)transaction
                   success:(void (^)(TSAttachmentStream *attachmentStream))successHandler
                   failure:(void (^)(NSError *error))failureHandler
{
    OWSAssert(transaction);

    [self setAttachment:attachment isDownloadingInMessage:message transaction:transaction];

    void (^markAndHandleFailure)(NSError *) = ^(NSError *error) {
        // Ensure enclosing transaction is complete.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self setAttachment:attachment didFailInMessage:message error:error];
            failureHandler(error);
        });
    };

    void (^markAndHandleSuccess)(TSAttachmentStream *attachmentStream) = ^(TSAttachmentStream *attachmentStream) {
        // Ensure enclosing transaction is complete.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            successHandler(attachmentStream);
            if (message) {
                [message touch];
            }
        });
    };

    if (attachment.serverId < 100) {
        DDLogError(@"%@ Suspicious attachment id: %llu", self.tag, (unsigned long long)attachment.serverId);
    }
    TSAttachmentRequest *attachmentRequest = [[TSAttachmentRequest alloc] initWithId:attachment.serverId relay:attachment.relay];

    [self.networkManager makeRequest:attachmentRequest
        success:^(NSURLSessionDataTask *task, id responseObject) {
            if (![responseObject isKindOfClass:[NSDictionary class]]) {
                DDLogError(@"%@ Failed retrieval of attachment. Response had unexpected format.", self.tag);
                NSError *error = OWSErrorMakeUnableToProcessServerResponseError();
                return markAndHandleFailure(error);
            }
            NSString *location = [(NSDictionary *)responseObject objectForKey:@"location"];
            if (!location) {
                DDLogError(@"%@ Failed retrieval of attachment. Response had no location.", self.tag);
                NSError *error = OWSErrorMakeUnableToProcessServerResponseError();
                return markAndHandleFailure(error);
            }

            dispatch_async([OWSDispatch attachmentsQueue], ^{
                [self downloadFromLocation:location
                    pointer:attachment
                    success:^(NSData *_Nonnull encryptedData) {
                        [self decryptAttachmentData:encryptedData
                                            pointer:attachment
                                            success:markAndHandleSuccess
                                            failure:markAndHandleFailure];
                    }
                    failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                        if (attachment.serverId < 100) {
                            // This looks like the symptom of the "frequent 404
                            // downloading attachments with low server ids".
                            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
                            NSInteger statusCode = [httpResponse statusCode];
                            OWSFail(@"%@ %d Failure with suspicious attachment id: %llu, %@",
                                self.tag,
                                (int)statusCode,
                                (unsigned long long)attachment.serverId,
                                error);
                        }
                        if (markAndHandleFailure) {
                            markAndHandleFailure(error);
                        }
                    }];
            });
        }
        failure:^(NSURLSessionDataTask *task, NSError *error) {
            if (!IsNSErrorNetworkFailure(error)) {
                OWSProdError([OWSAnalyticsEvents errorAttachmentRequestFailed]);
            }
            DDLogError(@"Failed retrieval of attachment with error: %@", error);
            if (attachment.serverId < 100) {
                // This _shouldn't_ be the symptom of the "frequent 404
                // downloading attachments with low server ids".
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
                NSInteger statusCode = [httpResponse statusCode];
                OWSFail(@"%@ %d Failure with suspicious attachment id: %llu, %@",
                    self.tag,
                    (int)statusCode,
                    (unsigned long long)attachment.serverId,
                    error);
            }
            return markAndHandleFailure(error);
        }];
}

- (void)decryptAttachmentData:(NSData *)cipherText
                      pointer:(TSAttachmentPointer *)attachment
                      success:(void (^)(TSAttachmentStream *attachmentStream))successHandler
                      failure:(void (^)(NSError *error))failureHandler
{
    NSError *decryptError;
    NSData *plaintext = [Cryptography decryptAttachment:cipherText
                                                withKey:attachment.encryptionKey
                                                 digest:attachment.digest
                                           unpaddedSize:attachment.byteCount
                                                  error:&decryptError];

    if (decryptError) {
        DDLogError(@"%@ failed to decrypt with error: %@", self.tag, decryptError);
        failureHandler(decryptError);
        return;
    }

    if (!plaintext) {
        NSError *error = OWSErrorWithCodeDescription(OWSErrorCodeFailedToDecryptMessage, NSLocalizedString(@"ERROR_MESSAGE_INVALID_MESSAGE", @""));
        failureHandler(error);
        return;
    }

    TSAttachmentStream *stream = [[TSAttachmentStream alloc] initWithPointer:attachment];

    NSError *writeError;
    [stream writeData:plaintext error:&writeError];
    if (writeError) {
        DDLogError(@"%@ Failed writing attachment stream with error: %@", self.tag, writeError);
        failureHandler(writeError);
        return;
    }

    [stream save];
    successHandler(stream);
}

- (void)downloadFromLocation:(NSString *)location
                     pointer:(TSAttachmentPointer *)pointer
                     success:(void (^)(NSData *encryptedData))successHandler
                     failure:(void (^)(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error))failureHandler
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer     = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setValue:OWSMimeTypeApplicationOctetStream forHTTPHeaderField:@"Content-Type"];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.completionQueue    = dispatch_get_main_queue();

    // We want to avoid large downloads from a compromised or buggy service.
    const long kMaxDownloadSize = 150 * 1024 * 1024;
    // TODO stream this download rather than storing the entire blob.
    __block NSURLSessionDataTask *task = nil;
    __block BOOL hasCheckedContentLength = NO;
    task = [manager GET:location
        parameters:nil
        progress:^(NSProgress *_Nonnull progress) {
            OWSAssert(progress != nil);
            
            // Don't do anything until we've received at least one byte of data.
            if (progress.completedUnitCount < 1) {
                return;
            }

            void (^abortDownload)() = ^{
                OWSFail(@"%@ Download aborted.", self.tag);
                [task cancel];
            };

            if (progress.totalUnitCount > kMaxDownloadSize || progress.completedUnitCount > kMaxDownloadSize) {
                // A malicious service might send a misleading content length header,
                // so....
                //
                // If the current downloaded bytes or the expected total byes
                // exceed the max download size, abort the download.
                DDLogError(@"%@ Attachment download exceed expected content length: %lld, %lld.",
                           self.tag,
                           (long long) progress.totalUnitCount,
                           (long long) progress.completedUnitCount);
                abortDownload();
                return;
            }

            [self fireProgressNotification:MAX(kAttachmentDownloadProgressTheta, progress.fractionCompleted)
                              attachmentId:pointer.uniqueId];

            // We only need to check the content length header once.
            if (hasCheckedContentLength) {
                return;
            }
            
            // Once we've received some bytes of the download, check the content length
            // header for the download.
            //
            // If the task doesn't exist, or doesn't have a response, or is missing
            // the expected headers, or has an invalid or oversize content length, etc.,
            // abort the download.
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
            if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                DDLogError(@"%@ Attachment download has missing or invalid response.",
                           self.tag);
                abortDownload();
                return;
            }
            
            NSDictionary *headers = [httpResponse allHeaderFields];
            if (![headers isKindOfClass:[NSDictionary class]]) {
                DDLogError(@"%@ Attachment download invalid headers.",
                           self.tag);
                abortDownload();
                return;
            }
            
            
            NSString *contentLength = headers[@"Content-Length"];
            if (![contentLength isKindOfClass:[NSString class]]) {
                DDLogError(@"%@ Attachment download missing or invalid content length.",
                           self.tag);
                abortDownload();
                return;
            }
            
            
            if (contentLength.longLongValue > kMaxDownloadSize) {
                DDLogError(@"%@ Attachment download content length exceeds max download size.",
                           self.tag);
                abortDownload();
                return;
            }
            
            // This response has a valid content length that is less
            // than our max download size.  Proceed with the download.
            hasCheckedContentLength = YES;
        }
        success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (![responseObject isKindOfClass:[NSData class]]) {
                    DDLogError(@"%@ Failed retrieval of attachment. Response had unexpected format.", self.tag);
                    NSError *error = OWSErrorMakeUnableToProcessServerResponseError();
                    return failureHandler(task, error);
                }
                successHandler((NSData *)responseObject);
            });
        }
        failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                DDLogError(@"Failed to retrieve attachment with error: %@", error.description);
                return failureHandler(task, error);
            });
        }];
}

- (void)fireProgressNotification:(CGFloat)progress attachmentId:(NSString *)attachmentId
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationNameAsync:kAttachmentDownloadProgressNotification
                                           object:nil
                                         userInfo:@{
                                             kAttachmentDownloadProgressKey : @(progress),
                                             kAttachmentDownloadAttachmentIDKey : attachmentId
                                         }];
}

- (void)setAttachment:(TSAttachmentPointer *)pointer
    isDownloadingInMessage:(nullable TSMessage *)message
               transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OWSAssert(transaction);

    pointer.state = TSAttachmentPointerStateDownloading;
    [pointer saveWithTransaction:transaction];
    if (message) {
        [message touchWithTransaction:transaction];
    }
}

- (void)setAttachment:(TSAttachmentPointer *)pointer
     didFailInMessage:(nullable TSMessage *)message
                error:(NSError *)error
{
    pointer.mostRecentFailureLocalizedText = error.localizedDescription;
    pointer.state = TSAttachmentPointerStateFailed;
    [pointer save];
    if (message) {
        [message touch];
    }
}

- (BOOL)hasSupportedAttachments
{
    return self.supportedAttachmentPointers.count > 0;
}

#pragma mark - Logging

+ (NSString *)tag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)tag
{
    return self.class.tag;
}

@end

NS_ASSUME_NONNULL_END
