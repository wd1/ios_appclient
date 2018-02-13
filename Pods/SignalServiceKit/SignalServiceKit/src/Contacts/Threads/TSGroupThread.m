//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSGroupThread.h"
#import "NSData+Base64.h"
#import "SignalRecipient.h"
#import "TSAttachmentStream.h"
#import <SignalServiceKit/TSAccountManager.h>
#import <YapDatabase/YapDatabaseConnection.h>
#import <YapDatabase/YapDatabaseTransaction.h>

NS_ASSUME_NONNULL_BEGIN

@implementation TSGroupThread

#define TSGroupThreadPrefix @"g"

- (instancetype)initWithGroupModel:(TSGroupModel *)groupModel
{
    OWSAssert(groupModel);
    OWSAssert(groupModel.groupId.length > 0);
    OWSAssert(groupModel.groupMemberIds.count > 0);
    for (NSString *recipientId in groupModel.groupMemberIds) {
        OWSAssert(recipientId.length > 0);
    }

    NSString *uniqueIdentifier = [[self class] threadIdFromGroupId:groupModel.groupId];
    self = [super initWithUniqueId:uniqueIdentifier];
    if (!self) {
        return self;
    }

    _groupModel = groupModel;

    return self;
}

- (instancetype)initWithGroupId:(NSData *)groupId
{
    OWSAssert(groupId.length > 0);

    NSString *localNumber = [TSAccountManager localNumber];
    OWSAssert(localNumber.length > 0);

    TSGroupModel *groupModel = [[TSGroupModel alloc] initWithTitle:nil
                                                         memberIds:[@[
                                                             localNumber,
                                                         ] mutableCopy]
                                                             image:nil
                                                           groupId:groupId];

    self = [self initWithGroupModel:groupModel];
    if (!self) {
        return self;
    }

    return self;
}

+ (nullable instancetype)threadWithGroupId:(NSData *)groupId transaction:(YapDatabaseReadTransaction *)transaction
{
    OWSAssert(groupId.length > 0);

    return [self fetchObjectWithUniqueID:[self threadIdFromGroupId:groupId] transaction:transaction];
}

+ (instancetype)getOrCreateThreadWithGroupId:(NSData *)groupId
                                 transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OWSAssert(groupId.length > 0);
    OWSAssert(transaction);

    TSGroupThread *thread = [self fetchObjectWithUniqueID:[self threadIdFromGroupId:groupId] transaction:transaction];
    if (!thread) {
        thread = [[self alloc] initWithGroupId:groupId];
        thread.isPendingAccept = YES;
        [thread saveWithTransaction:transaction];
    }
    return thread;
}

+ (instancetype)getOrCreateThreadWithGroupId:(NSData *)groupId
{
    OWSAssert(groupId.length > 0);

    __block TSGroupThread *thread;
    [[self dbReadWriteConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        thread = [self getOrCreateThreadWithGroupId:groupId transaction:transaction];
    }];
    return thread;
}

+ (instancetype)getOrCreateThreadWithGroupModel:(TSGroupModel *)groupModel
                                    transaction:(YapDatabaseReadWriteTransaction *)transaction {
    OWSAssert(groupModel);
    OWSAssert(groupModel.groupId.length > 0);
    OWSAssert(transaction);

    TSGroupThread *thread =
        [self fetchObjectWithUniqueID:[self threadIdFromGroupId:groupModel.groupId] transaction:transaction];

    if (!thread) {
        thread = [[TSGroupThread alloc] initWithGroupModel:groupModel];
        [thread saveWithTransaction:transaction];
    }
    return thread;
}

+ (instancetype)getOrCreateThreadWithGroupModel:(TSGroupModel *)groupModel
{
    OWSAssert(groupModel);
    OWSAssert(groupModel.groupId.length > 0);

    __block TSGroupThread *thread;
    [[self dbReadWriteConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        thread = [self getOrCreateThreadWithGroupModel:groupModel transaction:transaction];
    }];
    return thread;
}

+ (NSString *)threadIdFromGroupId:(NSData *)groupId
{
    OWSAssert(groupId.length > 0);

    return [TSGroupThreadPrefix stringByAppendingString:[groupId base64EncodedString]];
}

+ (NSData *)groupIdFromThreadId:(NSString *)threadId
{
    OWSAssert(threadId.length > 0);

    return [NSData dataFromBase64String:[threadId substringWithRange:NSMakeRange(1, threadId.length - 1)]];
}

- (NSArray<NSString *> *)recipientIdentifiers
{
    NSMutableArray<NSString *> *groupMemberIds = [self.groupModel.groupMemberIds mutableCopy];
    if (groupMemberIds == nil) {
        return @[];
    }

    [groupMemberIds removeObject:[TSAccountManager localNumber]];

    return [groupMemberIds copy];
}

// Group and Contact threads share a collection, this is a convenient way to enumerate *just* the group threads
+ (void)enumerateGroupThreadsUsingBlock:(void (^)(TSGroupThread *groupThread, BOOL *stop))block
{
    [self enumerateCollectionObjectsUsingBlock:^(id obj, BOOL *stop) {
        if ([obj isKindOfClass:[TSGroupThread class]]) {
            block((TSGroupThread *)obj, stop);
        }
    }];
}

// @returns all threads to which the recipient is a member.
//
// @note If this becomes a hotspot we can extract into a YapDB View.
// As is, the number of groups should be small (dozens, *maybe* hundreds), and we only enumerate them upon SN changes.
+ (NSArray<TSGroupThread *> *)groupThreadsWithRecipientId:(NSString *)recipientId
{
    NSMutableArray<TSGroupThread *> *groupThreads = [NSMutableArray new];

    [self enumerateGroupThreadsUsingBlock:^(TSGroupThread *_Nonnull groupThread, BOOL *_Nonnull stop) {
        if ([groupThread.groupModel.groupMemberIds containsObject:recipientId]) {
            [groupThreads addObject:groupThread];
        }
    }];

    return [groupThreads copy];
}

- (BOOL)isGroupThread
{
    return true;
}

- (NSString *)name
{
    return self.groupModel.groupName ? self.groupModel.groupName : NSLocalizedString(@"NEW_GROUP_DEFAULT_TITLE", @"");
}

- (void)updateAvatarWithAttachmentStream:(TSAttachmentStream *)attachmentStream
{
    [self.dbReadWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self updateAvatarWithAttachmentStream:attachmentStream transaction:transaction];
    }];
}

- (void)updateAvatarWithAttachmentStream:(TSAttachmentStream *)attachmentStream
                             transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OWSAssert(attachmentStream);
    OWSAssert(transaction);

    self.groupModel.groupImage = [attachmentStream image];
    [self saveWithTransaction:transaction];

    // Avatars are stored directly in the database, so there's no need
    // to keep the attachment around after assigning the image.
    [attachmentStream removeWithTransaction:transaction];
}

@end

NS_ASSUME_NONNULL_END
