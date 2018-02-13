//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSMessage.h"
#import "NSDate+OWS.h"
#import "TSAttachment.h"
#import "TSAttachmentPointer.h"
#import "TSThread.h"
#import <YapDatabase/YapDatabase.h>
#import <YapDatabase/YapDatabaseTransaction.h>

NS_ASSUME_NONNULL_BEGIN

static const NSUInteger OWSMessageSchemaVersion = 3;

@interface TSMessage ()

/**
 * The version of the model class's schema last used to serialize this model. Use this to manage data migrations during
 * object de/serialization.
 *
 * e.g.
 *
 *    - (id)initWithCoder:(NSCoder *)coder
 *    {
 *      self = [super initWithCoder:coder];
 *      if (!self) { return self; }
 *      if (_schemaVersion < 2) {
 *        _newName = [coder decodeObjectForKey:@"oldName"]
 *      }
 *      ...
 *      _schemaVersion = 2;
 *    }
 */
@property (nonatomic, readonly) NSUInteger schemaVersion;

// The timestamp property is populated by the envelope,
// which is created by the sender.
//
// We typically want to order messages locally by when
// they were received & decrypted, not by when they were sent.
@property (nonatomic, readonly) uint64_t receivedAtTimestamp;

@end

#pragma mark -

@implementation TSMessage

- (instancetype)initWithTimestamp:(uint64_t)timestamp
{
    return [self initWithTimestamp:timestamp inThread:nil messageBody:nil];
}

- (instancetype)initWithTimestamp:(uint64_t)timestamp inThread:(nullable TSThread *)thread
{
    return [self initWithTimestamp:timestamp inThread:thread messageBody:nil attachmentIds:@[]];
}

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(nullable TSThread *)thread
                      messageBody:(nullable NSString *)body
{
    return [self initWithTimestamp:timestamp inThread:thread messageBody:body attachmentIds:@[]];
}

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(nullable TSThread *)thread
                      messageBody:(nullable NSString *)body
                    attachmentIds:(NSArray<NSString *> *)attachmentIds
{
    return [self initWithTimestamp:timestamp
                          inThread:thread
                       messageBody:body
                     attachmentIds:attachmentIds
                  expiresInSeconds:0];
}

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(nullable TSThread *)thread
                      messageBody:(nullable NSString *)body
                    attachmentIds:(NSArray<NSString *> *)attachmentIds
                 expiresInSeconds:(uint32_t)expiresInSeconds
{
    return [self initWithTimestamp:timestamp
                          inThread:thread
                       messageBody:body
                     attachmentIds:attachmentIds
                  expiresInSeconds:expiresInSeconds
                   expireStartedAt:0];
}

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(nullable TSThread *)thread
                      messageBody:(nullable NSString *)body
                    attachmentIds:(NSArray<NSString *> *)attachmentIds
                 expiresInSeconds:(uint32_t)expiresInSeconds
                  expireStartedAt:(uint64_t)expireStartedAt
{
    self = [super initWithTimestamp:timestamp inThread:thread];

    if (!self) {
        return self;
    }

    _schemaVersion = OWSMessageSchemaVersion;

    _body = body;
    _attachmentIds = attachmentIds ? [attachmentIds mutableCopy] : [NSMutableArray new];
    _expiresInSeconds = expiresInSeconds;
    _expireStartedAt = expireStartedAt;
    [self updateExpiresAt];
    _receivedAtTimestamp = [NSDate ows_millisecondTimeStamp];

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return self;
    }

    if (_schemaVersion < 3) {
        _expiresInSeconds = 0;
        _expireStartedAt = 0;
        _expiresAt = 0;
    }

    if (_schemaVersion < 2) {
        // renamed _attachments to _attachmentIds
        if (!_attachmentIds) {
            _attachmentIds = [coder decodeObjectForKey:@"attachments"];
        }
    }

    if (!_attachmentIds) {
        _attachmentIds = [NSMutableArray new];
    }

    if (_receivedAtTimestamp == 0) {
        // Upgrade from the older "receivedAtDate" and "receivedAt" properties if
        // necessary.
        NSDate *receivedAtDate = [coder decodeObjectForKey:@"receivedAtDate"];
        if (!receivedAtDate) {
            receivedAtDate = [coder decodeObjectForKey:@"receivedAt"];
        }
        if (receivedAtDate) {
            _receivedAtTimestamp = [NSDate ows_millisecondsSince1970ForDate:receivedAtDate];
        }
    }

    _schemaVersion = OWSMessageSchemaVersion;

    return self;
}

- (void)setExpiresInSeconds:(uint32_t)expiresInSeconds
{
    _expiresInSeconds = expiresInSeconds;
    [self updateExpiresAt];
}

- (void)setExpireStartedAt:(uint64_t)expireStartedAt
{
    _expireStartedAt = expireStartedAt;
    [self updateExpiresAt];
}

- (BOOL)shouldStartExpireTimer
{
    __block BOOL result;
    [self.dbReadConnection readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        result = [self shouldStartExpireTimer:transaction];
    }];
    return result;
}

- (BOOL)shouldStartExpireTimer:(YapDatabaseReadTransaction *)transaction
{
    return self.isExpiringMessage;
}

// TODO a downloaded media doesn't start counting until download is complete.
- (void)updateExpiresAt
{
    if (_expiresInSeconds > 0 && _expireStartedAt > 0) {
        _expiresAt = _expireStartedAt + _expiresInSeconds * 1000;
    } else {
        _expiresAt = 0;
    }
}

- (BOOL)hasAttachments
{
    return self.attachmentIds ? (self.attachmentIds.count > 0) : NO;
}

- (NSString *)debugDescription
{
    if ([self hasAttachments]) {
        NSString *attachmentId = self.attachmentIds[0];
        return [NSString stringWithFormat:@"Media Message with attachmentId:%@", attachmentId];
    } else {
        return [NSString stringWithFormat:@"%@ with body: %@", [self class], self.body];
    }
}

- (NSString *)previewTextWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    if ([self hasAttachments]) {
        NSString *attachmentId = self.attachmentIds[0];
        TSAttachment *attachment = [TSAttachment fetchObjectWithUniqueID:attachmentId transaction:transaction];
        if (attachment) {
            return attachment.description;
        } else {
            return NSLocalizedString(@"UNKNOWN_ATTACHMENT_LABEL", @"In Inbox view, last message label for thread with corrupted attachment.");
        }
    } else {
        return self.body;
    }
}

// TODO deprecate this and implement something like previewTextWithTransaction: for all TSInteractions
- (NSString *)description
{
    if ([self hasAttachments]) {
        NSString *attachmentId = self.attachmentIds[0];
        TSAttachment *attachment = [TSAttachment fetchObjectWithUniqueID:attachmentId];
        if (attachment) {
            return attachment.description;
        } else {
            return NSLocalizedString(@"UNKNOWN_ATTACHMENT_LABEL", @"In Inbox view, last message label for thread with corrupted attachment.");
        }
    } else {
        return self.body;
    }
}

- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [super removeWithTransaction:transaction];

    for (NSString *attachmentId in self.attachmentIds) {
        TSAttachment *attachment = [TSAttachment fetchObjectWithUniqueID:attachmentId transaction:transaction];
        [attachment removeWithTransaction:transaction];
    };

    // Updates inbox thread preview
    [self touchThreadWithTransaction:transaction];
}

- (void)touchThreadWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [transaction touchObjectForKey:self.uniqueThreadId inCollection:[TSThread collection]];
}

- (BOOL)isExpiringMessage
{
    return self.expiresInSeconds > 0;
}

- (uint64_t)timestampForSorting
{
    if ([self shouldUseReceiptDateForSorting] && self.receivedAtTimestamp > 0) {
        return self.receivedAtTimestamp;
    } else {
        OWSAssert(self.timestamp > 0);
        return self.timestamp;
    }
}

- (BOOL)shouldUseReceiptDateForSorting
{
    return YES;
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
