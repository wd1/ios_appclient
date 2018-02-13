//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The users privacy preference for what kind of content to show in lock screen notifications.
 */
typedef NS_ENUM(NSUInteger, NotificationType) {
    NotificationNoNameNoPreview,
    NotificationNameNoPreview,
    NotificationNamePreview,
};

// Used when migrating logging to NSUserDefaults.
extern NSString *const PropertyListPreferencesSignalDatabaseCollection;
extern NSString *const PropertyListPreferencesKeyEnableDebugLog;

@interface PropertyListPreferences : NSObject

#pragma mark - Helpers

- (nullable id)tryGetValueForKey:(NSString *)key;
- (void)setValueForKey:(NSString *)key toValue:(nullable id)value;
- (void)clear;

#pragma mark - Specific Preferences

- (NSTimeInterval)getCachedOrDefaultDesiredBufferDepth;
- (void)setCachedDesiredBufferDepth:(double)value;

- (BOOL)getHasSentAMessage;
- (void)setHasSentAMessage:(BOOL)enabled;

- (BOOL)getHasArchivedAMessage;
- (void)setHasArchivedAMessage:(BOOL)enabled;

+ (BOOL)loggingIsEnabled;
+ (void)setLoggingEnabled:(BOOL)flag;

- (BOOL)screenSecurityIsEnabled;
- (void)setScreenSecurity:(BOOL)flag;

- (NotificationType)notificationPreviewType;
- (void)setNotificationPreviewType:(NotificationType)type;
- (NSString *)nameForNotificationPreviewType:(NotificationType)notificationType;

- (BOOL)soundInForeground;
- (void)setSoundInForeground:(BOOL)enabled;

+ (nullable NSString *)lastRanVersion;
+ (NSString *)setAndGetCurrentVersion;

- (BOOL)hasDeclinedNoContactsView;
- (void)setHasDeclinedNoContactsView:(BOOL)value;

- (void)setIOSUpgradeNagVersion:(NSString *)value;
- (nullable NSString *)iOSUpgradeNagVersion;

#pragma mark - Calling

#pragma mark Callkit

- (BOOL)isCallKitEnabled;
- (void)setIsCallKitEnabled:(BOOL)flag;
// Returns YES IFF isCallKitEnabled has been set by user.
- (BOOL)isCallKitEnabledSet;

- (BOOL)isCallKitPrivacyEnabled;
- (void)setIsCallKitPrivacyEnabled:(BOOL)flag;
// Returns YES IFF isCallKitPrivacyEnabled has been set by user.
- (BOOL)isCallKitPrivacySet;

#pragma mark direct call connectivity (non-TURN)

- (BOOL)doCallsHideIPAddress;
- (void)setDoCallsHideIPAddress:(BOOL)flag;

#pragma mark - Block on Identity Change

- (void)setIsSendingIdentityApprovalRequired:(BOOL)value;

#pragma mark - Push Tokens

- (void)setPushToken:(NSString *)value;
- (nullable NSString *)getPushToken;

@end

NS_ASSUME_NONNULL_END
