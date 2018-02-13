//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSAttachmentStream.h"
#import "MIMETypeUtil.h"
#import "NSData+Image.h"
#import "TSAttachmentPointer.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <YapDatabase/YapDatabase.h>
#import <YapDatabase/YapDatabaseTransaction.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSAttachmentStream ()

// We only want to generate the file path for this attachment once, so that
// changes in the file path generation logic don't break existing attachments.
@property (nullable, nonatomic) NSString *localRelativeFilePath;

// These properties should only be accessed on the main thread.
@property (nullable, nonatomic) NSNumber *cachedImageWidth;
@property (nullable, nonatomic) NSNumber *cachedImageHeight;
@property (nullable, nonatomic) NSNumber *cachedAudioDurationSeconds;

@end

#pragma mark -

@implementation TSAttachmentStream

- (instancetype)initWithContentType:(NSString *)contentType
                          byteCount:(UInt32)byteCount
                     sourceFilename:(nullable NSString *)sourceFilename
{
    self = [super initWithContentType:contentType byteCount:byteCount sourceFilename:sourceFilename];
    if (!self) {
        return self;
    }

    self.isDownloaded = YES;
    // TSAttachmentStream doesn't have any "incoming vs. outgoing"
    // state, but this constructor is used only for new outgoing
    // attachments which haven't been uploaded yet.
    _isUploaded = NO;
    _creationTimestamp = [NSDate new];

    [self ensureFilePath];

    return self;
}

- (instancetype)initWithPointer:(TSAttachmentPointer *)pointer
{
    // Once saved, this AttachmentStream will replace the AttachmentPointer in the attachments collection.
    self = [super initWithPointer:pointer];
    if (!self) {
        return self;
    }

    _contentType = pointer.contentType;
    self.isDownloaded = YES;
    // TSAttachmentStream doesn't have any "incoming vs. outgoing"
    // state, but this constructor is used only for new incoming
    // attachments which don't need to be uploaded.
    _isUploaded = YES;
    self.attachmentType = pointer.attachmentType;
    _creationTimestamp = [NSDate new];

    [self ensureFilePath];

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return self;
    }

    // OWS105AttachmentFilePaths will ensure the file path is saved if necessary.
    [self ensureFilePath];

    // OWS105AttachmentFilePaths will ensure the creation timestamp is saved if necessary.
    if (!_creationTimestamp) {
        _creationTimestamp = [NSDate new];
    }

    return self;
}

- (void)upgradeFromAttachmentSchemaVersion:(NSUInteger)attachmentSchemaVersion
{
    [super upgradeFromAttachmentSchemaVersion:attachmentSchemaVersion];

    if (attachmentSchemaVersion < 3) {
        // We want to treat any legacy TSAttachmentStream as though
        // they have already been uploaded.  If it needs to be reuploaded,
        // the OWSUploadingService will update this progress when the
        // upload begins.
        self.isUploaded = YES;
    }

    if (attachmentSchemaVersion < 4) {
        // Legacy image sizes don't correctly reflect image orientation.
        self.cachedImageWidth = nil;
        self.cachedImageHeight = nil;
    }
}

- (void)ensureFilePath
{
    if (self.localRelativeFilePath) {
        return;
    }

    NSString *attachmentsFolder = [[self class] attachmentsFolder];
    NSString *filePath = [MIMETypeUtil filePathForAttachment:self.uniqueId
                                                  ofMIMEType:self.contentType
                                              sourceFilename:self.sourceFilename
                                                    inFolder:attachmentsFolder];
    if (!filePath) {
        OWSFail(@"%@ Could not generate path for attachment.", self.tag);
        return;
    }
    if (![filePath hasPrefix:attachmentsFolder]) {
        OWSFail(@"%@ Attachment paths should all be in the attachments folder.", self.tag);
        return;
    }
    NSString *localRelativeFilePath = [filePath substringFromIndex:attachmentsFolder.length];
    if (localRelativeFilePath.length < 1) {
        OWSFail(@"%@ Empty local relative attachment paths.", self.tag);
        return;
    }

    self.localRelativeFilePath = localRelativeFilePath;
    OWSAssert(self.filePath);
}

#pragma mark - File Management

- (nullable NSData *)readDataFromFileWithError:(NSError **)error
{
    *error = nil;
    NSString *_Nullable filePath = self.filePath;
    if (!filePath) {
        OWSFail(@"%@ Missing path for attachment.", self.tag);
        return nil;
    }
    return [NSData dataWithContentsOfFile:filePath options:0 error:error];
}

- (BOOL)writeData:(NSData *)data error:(NSError **)error
{
    OWSAssert(data);

    *error = nil;
    NSString *_Nullable filePath = self.filePath;
    if (!filePath) {
        OWSFail(@"%@ Missing path for attachment.", self.tag);
        return NO;
    }
    DDLogInfo(@"%@ Writing attachment to file: %@", self.tag, filePath);
    return [data writeToFile:filePath options:0 error:error];
}

- (BOOL)writeDataSource:(DataSource *)dataSource
{
    OWSAssert(dataSource);

    NSString *_Nullable filePath = self.filePath;
    if (!filePath) {
        OWSFail(@"%@ Missing path for attachment.", self.tag);
        return NO;
    }
    DDLogInfo(@"%@ Writing attachment to file: %@", self.tag, filePath);
    return [dataSource writeToPath:filePath];
}

+ (NSString *)attachmentsFolder
{
    static NSString *attachmentsFolder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documentsPath =
            [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        attachmentsFolder = [documentsPath stringByAppendingPathComponent:@"Attachments"];

        BOOL isDirectory;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:attachmentsFolder isDirectory:&isDirectory];
        if (exists) {
            OWSAssert(isDirectory);

            DDLogInfo(@"Attachments directory already exists");
        } else {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:attachmentsFolder
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error) {
                DDLogError(@"Failed to create attachments directory: %@", error);
            }
        }
    });
    return attachmentsFolder;
}

- (nullable NSString *)filePath
{
    if (!self.localRelativeFilePath) {
        OWSFail(@"%@ Attachment missing local file path.", self.tag);
        return nil;
    }

    return [[[self class] attachmentsFolder] stringByAppendingPathComponent:self.localRelativeFilePath];
}

- (nullable NSURL *)mediaURL
{
    NSString *_Nullable filePath = self.filePath;
    if (!filePath) {
        OWSFail(@"%@ Missing path for attachment.", self.tag);
        return nil;
    }
    return [NSURL fileURLWithPath:filePath];
}

- (void)removeFileWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    NSString *_Nullable filePath = self.filePath;
    if (!filePath) {
        OWSFail(@"%@ Missing path for attachment.", self.tag);
        return;
    }
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];

    if (error) {
        DDLogError(@"%@ remove file errored with: %@", self.tag, error);
    }
}

- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [super removeWithTransaction:transaction];
    [self removeFileWithTransaction:transaction];
}

- (BOOL)isAnimated {
    return [MIMETypeUtil isAnimated:self.contentType];
}

- (BOOL)isImage {
    return [MIMETypeUtil isImage:self.contentType];
}

- (BOOL)isVideo {
    return [MIMETypeUtil isVideo:self.contentType];
}

- (BOOL)isAudio {
    return [MIMETypeUtil isAudio:self.contentType];
}

- (nullable UIImage *)image
{
    if ([self isVideo]) {
        return [self videoThumbnail];
    } else if ([self isImage] || [self isAnimated]) {
        NSURL *_Nullable mediaUrl = [self mediaURL];
        if (!mediaUrl) {
            return nil;
        }
        NSData *data = [NSData dataWithContentsOfURL:mediaUrl];
        if (![data ows_isValidImage]) {
            return nil;
        }
        return [UIImage imageWithData:data];
    } else {
        return nil;
    }
}

- (nullable UIImage *)videoThumbnail
{
    NSURL *_Nullable mediaUrl = [self mediaURL];
    if (!mediaUrl) {
        return nil;
    }
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:mediaUrl options:nil];
    AVAssetImageGenerator *generate         = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generate.appliesPreferredTrackTransform = YES;
    NSError *err                            = NULL;
    CMTime time                             = CMTimeMake(1, 60);
    CGImageRef imgRef                       = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
    return [[UIImage alloc] initWithCGImage:imgRef];
}

+ (void)deleteAttachments
{
    NSError *error;

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSURL *fileURL = [NSURL fileURLWithPath:self.attachmentsFolder];
    NSArray<NSURL *> *contents =
        [fileManager contentsOfDirectoryAtURL:fileURL includingPropertiesForKeys:nil options:0 error:&error];

    if (error) {
        OWSFail(@"failed to get contents of attachments folder: %@ with error: %@", self.attachmentsFolder, error);
        return;
    }

    for (NSURL *url in contents) {
        NSError *deletionError;
        [fileManager removeItemAtURL:url error:&deletionError];
        if (deletionError) {
            OWSFail(@"failed to remove item at path: %@ with error: %@", url, deletionError);
            // continue to try to delete remaining items.
        }
    }

    return;
}

- (CGSize)calculateImageSize
{
    if ([self isVideo]) {
        return [self videoThumbnail].size;
    } else if ([self isImage] || [self isAnimated]) {
        NSURL *_Nullable mediaUrl = [self mediaURL];
        if (!mediaUrl) {
            return CGSizeZero;
        }
        if (![NSData ows_isValidImageAtPath:mediaUrl.path]) {
            return CGSizeZero;
        }

        // With CGImageSource we avoid loading the whole image into memory.
        CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)mediaUrl, NULL);
        if (!source) {
            OWSFail(@"%@ Could not load image: %@", self.tag, mediaUrl);
            return CGSizeZero;
        }

        NSDictionary *options = @{
            (NSString *)kCGImageSourceShouldCache : @(NO),
        };
        NSDictionary *properties
            = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, 0, (CFDictionaryRef)options);
        CGSize imageSize = CGSizeZero;
        if (properties) {
            NSNumber *orientation = properties[(NSString *)kCGImagePropertyOrientation];
            NSNumber *width = properties[(NSString *)kCGImagePropertyPixelWidth];
            NSNumber *height = properties[(NSString *)kCGImagePropertyPixelHeight];

            if (width && height) {
                imageSize = CGSizeMake(width.floatValue, height.floatValue);

                if (orientation) {
                    imageSize =
                        [self applyImageOrientation:(UIImageOrientation)orientation.intValue toImageSize:imageSize];
                }
            } else {
                OWSFail(@"%@ Could not determine size of image: %@", self.tag, mediaUrl);
            }
        }
        CFRelease(source);
        return imageSize;
    } else {
        return CGSizeZero;
    }
}

- (CGSize)applyImageOrientation:(UIImageOrientation)orientation toImageSize:(CGSize)imageSize
{
    switch (orientation) {
        case UIImageOrientationUp: // EXIF = 1
        case UIImageOrientationUpMirrored: // EXIF = 2
        case UIImageOrientationDown: // EXIF = 3
        case UIImageOrientationDownMirrored: // EXIF = 4
            return imageSize;
        case UIImageOrientationLeftMirrored: // EXIF = 5
        case UIImageOrientationLeft: // EXIF = 6
        case UIImageOrientationRightMirrored: // EXIF = 7
        case UIImageOrientationRight: // EXIF = 8
            return CGSizeMake(imageSize.height, imageSize.width);
        default:
            return imageSize;
    }
}

- (CGSize)ensureCachedImageSizeWithTransaction:(YapDatabaseReadWriteTransaction *_Nullable)transaction
{
    OWSAssert([NSThread isMainThread]);

    if (self.cachedImageWidth && self.cachedImageHeight) {
        return CGSizeMake(self.cachedImageWidth.floatValue, self.cachedImageHeight.floatValue);
    }

    CGSize imageSize = [self calculateImageSize];
    self.cachedImageWidth = @(imageSize.width);
    self.cachedImageHeight = @(imageSize.height);

    void (^updateDataStore)() = ^(YapDatabaseReadWriteTransaction *transaction) {
        OWSAssert(transaction);

        NSString *collection = [[self class] collection];
        TSAttachmentStream *latestInstance = [transaction objectForKey:self.uniqueId inCollection:collection];
        if (latestInstance) {
            latestInstance.cachedImageWidth = @(imageSize.width);
            latestInstance.cachedImageHeight = @(imageSize.height);
            [latestInstance saveWithTransaction:transaction];
        } else {
            // This message has not yet been saved; do nothing.
            OWSFail(@"%@ Attachment not yet saved.", self.tag);
        }
    };

    if (transaction) {
        updateDataStore(transaction);
    } else {
        [self.dbReadWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            updateDataStore(transaction);
        }];
    }

    return imageSize;
}

- (CGSize)imageSizeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OWSAssert([NSThread isMainThread]);
    OWSAssert(transaction);

    return [self ensureCachedImageSizeWithTransaction:transaction];
}

- (CGSize)imageSizeWithoutTransaction
{
    OWSAssert([NSThread isMainThread]);

    return [self ensureCachedImageSizeWithTransaction:nil];
}

- (CGFloat)calculateAudioDurationSeconds
{
    OWSAssert([NSThread isMainThread]);
    OWSAssert([self isAudio]);

    NSError *error;
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.mediaURL error:&error];
    if (error && [error.domain isEqualToString:NSOSStatusErrorDomain]
        && (error.code == kAudioFileInvalidFileError || error.code == kAudioFileStreamError_InvalidFile)) {
        // Ignore "invalid audio file" errors.
        return 0.f;
    }
    if (!error) {
        return (CGFloat)[audioPlayer duration];
    } else {
        OWSFail(@"Could not find audio duration: %@", self.mediaURL);
        return 0;
    }
}

- (CGFloat)ensureCachedAudioDurationSecondsWithTransaction:(YapDatabaseReadWriteTransaction *_Nullable)transaction
{
    OWSAssert([NSThread isMainThread]);

    if (self.cachedAudioDurationSeconds) {
        return self.cachedAudioDurationSeconds.floatValue;
    }

    CGFloat audioDurationSeconds = [self calculateAudioDurationSeconds];
    self.cachedAudioDurationSeconds = @(audioDurationSeconds);

    void (^updateDataStore)() = ^(YapDatabaseReadWriteTransaction *transaction) {
        OWSAssert(transaction);

        NSString *collection = [[self class] collection];
        TSAttachmentStream *latestInstance = [transaction objectForKey:self.uniqueId inCollection:collection];
        if (latestInstance) {
            latestInstance.cachedAudioDurationSeconds = @(audioDurationSeconds);
            [latestInstance saveWithTransaction:transaction];
        } else {
            // This message has not yet been saved; do nothing.
            OWSFail(@"%@ Attachment not yet saved.", self.tag);
        }
    };

    if (transaction) {
        updateDataStore(transaction);
    } else {
        [self.dbReadWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            updateDataStore(transaction);
        }];
    }

    return audioDurationSeconds;
}

- (CGFloat)audioDurationSecondsWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OWSAssert([NSThread isMainThread]);
    OWSAssert(transaction);

    return [self ensureCachedAudioDurationSecondsWithTransaction:transaction];
}

- (CGFloat)audioDurationSecondsWithoutTransaction
{
    OWSAssert([NSThread isMainThread]);

    return [self ensureCachedAudioDurationSecondsWithTransaction:nil];
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
