//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSGroupModel.h"
#import "TSThread.h"

NS_ASSUME_NONNULL_BEGIN

@class TSAttachmentStream;
@class YapDatabaseReadWriteTransaction;

@interface TSGroupThread : TSThread

@property (nonatomic, strong) TSGroupModel *groupModel;

+ (instancetype)getOrCreateThreadWithGroupModel:(TSGroupModel *)groupModel;
+ (instancetype)getOrCreateThreadWithGroupModel:(TSGroupModel *)groupModel
                                    transaction:(YapDatabaseReadWriteTransaction *)transaction;

+ (instancetype)getOrCreateThreadWithGroupId:(NSData *)groupId;
+ (instancetype)getOrCreateThreadWithGroupId:(NSData *)groupId
                                 transaction:(YapDatabaseReadWriteTransaction *)transaction;

+ (nullable instancetype)threadWithGroupId:(NSData *)groupId transaction:(YapDatabaseReadTransaction *)transaction;

+ (NSString *)threadIdFromGroupId:(NSData *)groupId;

// all group threads containing recipient as a member
+ (NSArray<TSGroupThread *> *)groupThreadsWithRecipientId:(NSString *)recipientId;

- (void)updateAvatarWithAttachmentStream:(TSAttachmentStream *)attachmentStream;
- (void)updateAvatarWithAttachmentStream:(TSAttachmentStream *)attachmentStream
                             transaction:(YapDatabaseReadWriteTransaction *)transaction;

@end

NS_ASSUME_NONNULL_END
