//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSAttachmentPointer.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TSAttachmentPointer

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return self;
    }

    // A TSAttachmentPointer is a yet-to-be-downloaded attachment.
    // If this is an old TSAttachmentPointer from another session,
    // we know that it failed to complete before the session completed.
    if (![coder containsValueForKey:@"state"]) {
        _state = TSAttachmentPointerStateFailed;
    }

    return self;
}

- (instancetype)initWithServerId:(UInt64)serverId
                             key:(NSData *)key
                          digest:(nullable NSData *)digest
                       byteCount:(UInt32)byteCount
                     contentType:(NSString *)contentType
                           relay:(NSString *)relay
                  sourceFilename:(nullable NSString *)sourceFilename
                  attachmentType:(TSAttachmentType)attachmentType
{
    self = [super initWithServerId:serverId
                     encryptionKey:key
                         byteCount:byteCount
                       contentType:contentType
                    sourceFilename:sourceFilename];
    if (!self) {
        return self;
    }

    _digest = digest;
    _state = TSAttachmentPointerStateEnqueued;
    _relay = relay;
    self.attachmentType = attachmentType;

    return self;
}

- (BOOL)isDecimalNumberText:(NSString *)text
{
    return [text componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]].count == 1;
}

- (void)upgradeFromAttachmentSchemaVersion:(NSUInteger)attachmentSchemaVersion
{
    // Legacy instances of TSAttachmentPointer apparently used the serverId as their
    // uniqueId.
    if (attachmentSchemaVersion < 2 && self.serverId == 0) {
        OWSAssert([self isDecimalNumberText:self.uniqueId]);
        if ([self isDecimalNumberText:self.uniqueId]) {
            // For legacy instances, try to parse the serverId from the uniqueId.
            self.serverId = [self.uniqueId integerValue];
        } else {
            DDLogError(@"%@ invalid legacy attachment uniqueId: %@.", self.tag, self.uniqueId);
        }
    }
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
