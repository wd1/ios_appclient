//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSAttachment.h"
#import "MIMETypeUtil.h"

NS_ASSUME_NONNULL_BEGIN

NSUInteger const TSAttachmentSchemaVersion = 4;

@interface TSAttachment ()

@property (nonatomic, readonly) NSUInteger attachmentSchemaVersion;

@end

@implementation TSAttachment

// This constructor is used for new instances of TSAttachmentPointer,
// i.e. undownloaded incoming attachments.
- (instancetype)initWithServerId:(UInt64)serverId
                   encryptionKey:(NSData *)encryptionKey
                       byteCount:(UInt32)byteCount
                     contentType:(NSString *)contentType
                  sourceFilename:(nullable NSString *)sourceFilename
{
    OWSAssert(serverId > 0);
    OWSAssert(encryptionKey.length > 0);
    if (byteCount <= 0) {
        // This will fail with legacy iOS clients which don't upload attachment size.
        DDLogWarn(@"%@ Missing byteCount for attachment with serverId: %lld", self.tag, serverId);
    }

    self = [super init];
    if (!self) {
        return self;
    }

    _serverId = serverId;
    _encryptionKey = encryptionKey;
    _byteCount = byteCount;
    _contentType = contentType;
    _sourceFilename = sourceFilename;

    _attachmentSchemaVersion = TSAttachmentSchemaVersion;

    return self;
}

// This constructor is used for new instances of TSAttachmentStream
// that represent new, un-uploaded outgoing attachments.
- (instancetype)initWithContentType:(NSString *)contentType
                          byteCount:(UInt32)byteCount
                     sourceFilename:(nullable NSString *)sourceFilename
{
    OWSAssert(byteCount > 0);

    self = [super init];
    if (!self) {
        return self;
    }

    _contentType = contentType;
    _byteCount = byteCount;
    _sourceFilename = sourceFilename;

    _attachmentSchemaVersion = TSAttachmentSchemaVersion;

    return self;
}

// This constructor is used for new instances of TSAttachmentStream
// that represent downloaded incoming attachments.
- (instancetype)initWithPointer:(TSAttachment *)pointer
{
    OWSAssert(pointer.serverId > 0);
    OWSAssert(pointer.encryptionKey.length > 0);
    if (pointer.byteCount <= 0) {
        // This will fail with legacy iOS clients which don't upload attachment size.
        DDLogWarn(@"%@ Missing pointer.byteCount for attachment with serverId: %lld", self.tag, pointer.serverId);
    }

    // Once saved, this AttachmentStream will replace the AttachmentPointer in the attachments collection.
    self = [super initWithUniqueId:pointer.uniqueId];
    if (!self) {
        return self;
    }

    _serverId = pointer.serverId;
    _encryptionKey = pointer.encryptionKey;
    _byteCount = pointer.byteCount;
    _contentType = pointer.contentType;
    _sourceFilename = pointer.sourceFilename;

    _attachmentSchemaVersion = TSAttachmentSchemaVersion;

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return self;
    }

    if (_attachmentSchemaVersion < TSAttachmentSchemaVersion) {
        [self upgradeFromAttachmentSchemaVersion:_attachmentSchemaVersion];
        _attachmentSchemaVersion = TSAttachmentSchemaVersion;
    }

    if (!_sourceFilename) {
        // renamed _filename to _sourceFilename
        _sourceFilename = [coder decodeObjectForKey:@"filename"];
        OWSAssert(!_sourceFilename || [_sourceFilename isKindOfClass:[NSString class]]);
    }

    return self;
}

- (void)upgradeFromAttachmentSchemaVersion:(NSUInteger)attachmentSchemaVersion
{
    // This method is overridden by the base classes TSAttachmentPointer and
    // TSAttachmentStream.
}

+ (NSString *)collection {
    return @"TSAttachements";
}

- (NSString *)description {
    NSString *attachmentString = NSLocalizedString(@"ATTACHMENT", nil);

    if ([MIMETypeUtil isImage:self.contentType]) {
        return [NSString stringWithFormat:@"📷 %@", attachmentString];
    } else if ([MIMETypeUtil isVideo:self.contentType]) {
        return [NSString stringWithFormat:@"📽 %@", attachmentString];
    } else if ([MIMETypeUtil isAudio:self.contentType]) {

        // a missing filename is the legacy way to determine if an audio attachment is
        // a voice note vs. other arbitrary audio attachments.
        if (self.isVoiceMessage || !self.sourceFilename || self.sourceFilename.length == 0) {
            attachmentString = NSLocalizedString(@"ATTACHMENT_TYPE_VOICE_MESSAGE",
                @"Short text label for a voice message attachment, used for thread preview and on lockscreen");
            return [NSString stringWithFormat:@"🎤 %@", attachmentString];
        } else {
            return [NSString stringWithFormat:@"📻 %@", attachmentString];
        }
    } else if ([MIMETypeUtil isAnimated:self.contentType]) {
        return [NSString stringWithFormat:@"🎡 %@", attachmentString];
    }

    return attachmentString;
}

- (BOOL)isVoiceMessage
{
    return self.attachmentType == TSAttachmentTypeVoiceMessage;
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
