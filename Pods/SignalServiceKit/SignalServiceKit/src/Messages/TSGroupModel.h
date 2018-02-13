//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSYapDatabaseObject.h"
#import "ContactsManagerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const GroupUpdateTypeSting;
extern NSString *const GroupInfoString;

extern NSString *const GroupCreateMessage;
extern NSString *const GroupBecameMemberMessage;
extern NSString *const GroupUpdatedMessage;
extern NSString *const GroupTitleChangedMessage;
extern NSString *const GroupAvatarChangedMessage;
extern NSString *const GroupMemberLeftMessage;
extern NSString *const GroupMemberJoinedMessage;

@interface TSGroupModel : TSYapDatabaseObject

@property (nonatomic, strong, nullable) NSArray<NSString *> *groupMemberIds;
@property (nonatomic, strong, nullable) NSString *groupName;
@property (nonatomic, strong, nullable) NSData *groupId;

#if TARGET_OS_IOS
@property (nonatomic, strong, nullable) UIImage *groupImage;

- (nullable instancetype)initWithTitle:(NSString *)title
                    memberIds:(NSMutableArray<NSString *> *)memberIds
                        image:(nullable UIImage *)image
                      groupId:(nullable NSData *)groupId;

- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToGroupModel:(TSGroupModel *)model;
- (nullable NSDictionary *)getInfoAboutUpdateTo:(TSGroupModel *)newModel;
#endif

NS_ASSUME_NONNULL_END

@end
