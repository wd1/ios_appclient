//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class TSStorageManager;
@class TSMessage;
@class TSThread;
@protocol ContactsManagerProtocol;

@interface OWSDisappearingMessagesJob : NSObject

+ (instancetype)sharedJob;

- (instancetype)init NS_UNAVAILABLE;

+ (void)setExpirationsForThread:(TSThread *)thread;
+ (void)setExpirationForMessage:(TSMessage *)message;
+ (void)setExpirationForMessage:(TSMessage *)message expirationStartedAt:(uint64_t)expirationStartedAt;

/**
 * Synchronize our disappearing messages settings with that of the given message. Useful so we can
 * become eventually consistent with remote senders.
 *
 * @param message
 *   Can be an expiring or non expiring message. We match the expiration timer of the message, including disabling
 *   expiring messages if the message is not an expiring message.
 *
 * @param contactsManager
 *   Provides the contact name responsible for any configuration changes in an info message.
 */
+ (void)becomeConsistentWithConfigurationForMessage:(TSMessage *)message
                                    contactsManager:(id<ContactsManagerProtocol>)contactsManager;

// Clean up any messages that expired since last launch immediately
// and continue cleaning in the background.
- (void)startIfNecessary;

@end

NS_ASSUME_NONNULL_END
