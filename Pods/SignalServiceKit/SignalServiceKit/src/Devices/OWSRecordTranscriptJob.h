//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class OWSIncomingSentMessageTranscript;
@class OWSReadReceiptManager;
@class TSAttachmentStream;
@class TSNetworkManager;
@class TSStorageManager;
@class YapDatabaseReadWriteTransaction;

@protocol ContactsManagerProtocol;

// This job is used to process "outgoing message" notifications from linked devices.
@interface OWSRecordTranscriptJob : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithIncomingSentMessageTranscript:(OWSIncomingSentMessageTranscript *)incomingSentMessageTranscript;
- (instancetype)initWithIncomingSentMessageTranscript:(OWSIncomingSentMessageTranscript *)incomingSentMessageTranscript
                                       networkManager:(TSNetworkManager *)networkManager
                                       storageManager:(TSStorageManager *)storageManager
                                   readReceiptManager:(OWSReadReceiptManager *)readReceiptManager
                                      contactsManager:(id<ContactsManagerProtocol>)contactsManager
    NS_DESIGNATED_INITIALIZER;

- (void)runWithAttachmentHandler:(void (^)(TSAttachmentStream *attachmentStream))attachmentHandler
                     transaction:(YapDatabaseReadWriteTransaction *)transaction;

@end

NS_ASSUME_NONNULL_END
