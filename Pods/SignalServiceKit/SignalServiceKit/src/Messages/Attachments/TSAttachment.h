//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSYapDatabaseObject.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TSAttachmentType) {
    TSAttachmentTypeDefault = 0,
    TSAttachmentTypeVoiceMessage = 1,
};

@interface TSAttachment : TSYapDatabaseObject {

@protected
    NSString *_contentType;
}

// TSAttachment is a base class for TSAttachmentPointer (a yet-to-be-downloaded
// incoming attachment) and TSAttachmentStream (an outgoing or already-downloaded
// incoming attachment).
//
// The attachmentSchemaVersion and serverId properties only apply to
// TSAttachmentPointer, which can be distinguished by the isDownloaded
// property.
@property (atomic, readwrite) UInt64 serverId;
@property (atomic, readwrite) NSData *encryptionKey;
@property (nonatomic, readonly) NSString *contentType;
@property (atomic, readwrite) BOOL isDownloaded;
@property (nonatomic) TSAttachmentType attachmentType;

// Though now required, may incorrectly be 0 on legacy attachments.
@property (nonatomic, readonly) UInt32 byteCount;

// Represents the "source" filename sent or received in the protos,
// not the filename on disk.
@property (nonatomic, readonly, nullable) NSString *sourceFilename;

// This constructor is used for new instances of TSAttachmentPointer,
// i.e. undownloaded incoming attachments.
- (instancetype)initWithServerId:(UInt64)serverId
                   encryptionKey:(NSData *)encryptionKey
                       byteCount:(UInt32)byteCount
                     contentType:(NSString *)contentType
                  sourceFilename:(nullable NSString *)sourceFilename;

// This constructor is used for new instances of TSAttachmentStream
// that represent new, un-uploaded outgoing attachments.
- (instancetype)initWithContentType:(NSString *)contentType
                          byteCount:(UInt32)byteCount
                     sourceFilename:(nullable NSString *)sourceFilename;

// This constructor is used for new instances of TSAttachmentStream
// that represent downloaded incoming attachments.
- (instancetype)initWithPointer:(TSAttachment *)pointer;

- (nullable instancetype)initWithCoder:(NSCoder *)coder;

- (void)upgradeFromAttachmentSchemaVersion:(NSUInteger)attachmentSchemaVersion;

- (BOOL)isVoiceMessage;

@end

NS_ASSUME_NONNULL_END
