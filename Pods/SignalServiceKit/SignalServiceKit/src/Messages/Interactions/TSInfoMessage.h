//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSReadTracking.h"
#import "TSMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface TSInfoMessage : TSMessage <OWSReadTracking>

typedef NS_ENUM(NSInteger, TSInfoMessageType) {
    TSInfoMessageTypeSessionDidEnd,
    TSInfoMessageUserNotRegistered,
    // TSInfoMessageTypeUnsupportedMessage appears to be obsolete.
    TSInfoMessageTypeUnsupportedMessage,
    TSInfoMessageTypeGroupUpdate,
    TSInfoMessageTypeGroupQuit,
    TSInfoMessageTypeDisappearingMessagesUpdate,
    TSInfoMessageAddToContactsOffer,
    TSInfoMessageVerificationStateChange,
    TSInfoMessageAddUserToProfileWhitelistOffer,
    TSInfoMessageAddGroupToProfileWhitelistOffer,
};

+ (instancetype)userNotRegisteredMessageInThread:(TSThread *)thread;

@property (atomic, readonly) TSInfoMessageType messageType;
@property (atomic, readonly) NSString *customMessage;
@property (atomic, readonly) NSString *additionalInfoString;
@property (atomic, readonly) NSString *authorId;

- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(TSThread *)contact
                      messageType:(TSInfoMessageType)infoMessage NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(TSThread *)thread
                      messageType:(TSInfoMessageType)infoMessage
                    customMessage:(NSString *)customMessage;

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         authorId:(NSString *)authorId
                         inThread:(TSThread *)thread
                      messageType:(TSInfoMessageType)infoMessage
                    customMessage:(NSString *)customMessage
             additionalInfoString:(NSString *)additionalInfoString;

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         inThread:(nullable TSThread *)thread
                      messageBody:(nullable NSString *)body
                    attachmentIds:(NSArray<NSString *> *)attachmentIds
                 expiresInSeconds:(uint32_t)expiresInSeconds
                  expireStartedAt:(uint64_t)expireStartedAt NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
