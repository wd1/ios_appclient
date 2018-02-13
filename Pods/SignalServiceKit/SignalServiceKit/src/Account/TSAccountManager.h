//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSConstants.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const TSRegistrationErrorDomain;
extern NSString *const TSRegistrationErrorUserInfoHTTPStatus;
extern NSString *const kNSNotificationName_RegistrationStateDidChange;
extern NSString *const kNSNotificationName_LocalNumberDidChange;

@class TSNetworkManager;
@class TSStorageManager;

@interface TSAccountManager : NSObject

#pragma mark - Initializers

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithNetworkManager:(TSNetworkManager *)networkManager
                        storageManager:(TSStorageManager *)storageManager NS_DESIGNATED_INITIALIZER;

+ (instancetype)sharedInstance;

@property (nonatomic, strong, readonly) TSNetworkManager *networkManager;

/**
 *  Returns if a user is registered or not
 *
 *  @return registered or not
 */
+ (BOOL)isRegistered;

/**
 *  Returns current phone number for this device, which may not yet have been registered.
 *
 *  @return E164 formatted phone number
 */
+ (nullable NSString *)localNumber;
- (nullable NSString *)localNumber;

/**
 *  Symmetric key that's used to encrypt message payloads from the server,
 *
 *  @return signaling key
 */
+ (nullable NSString *)signalingKey;
- (nullable NSString *)signalingKey;

/**
 *  The server auth token allows the Signal client to connect to the Signal server
 *
 *  @return server authentication token
 */
+ (nullable NSString *)serverAuthToken;
- (nullable NSString *)serverAuthToken;


- (void)storeServerAuthToken:(NSString *)authToken signalingKey:(NSString *)signalingKey;

/**
 *  The registration ID is unique to an installation of TextSecure, it allows to know if the app was reinstalled
 *
 *  @return registrationID;
 */

+ (uint32_t)getOrGenerateRegistrationId;

#pragma mark - Register with phone number

+ (void)registerWithPhoneNumber:(NSString *)phoneNumber
                        success:(void (^)())successBlock
                        failure:(void (^)(NSError *error))failureBlock
                smsVerification:(BOOL)isSMS;

+ (void)rerequestSMSWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock;

+ (void)rerequestVoiceWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)verifyAccountWithCode:(NSString *)verificationCode
                      success:(void (^)())successBlock
                      failure:(void (^)(NSError *error))failureBlock;

- (void)registerForManualMessageFetchingWithSuccess:(void (^)())successBlock
                                            failure:(void (^)(NSError *error))failureBlock;

// Called once registration is complete - meaning the following have succeeded:
// - obtained signal server credentials
// - uploaded pre-keys
// - uploaded push tokens
- (void)didRegister;

- (void)storeLocalNumber:(NSString *)localNumber;

#if TARGET_OS_IPHONE

/**
 *  Register's the device's push notification token with the server
 *
 *  @param pushToken Apple's Push Token
 */
- (void)registerForPushNotificationsWithPushToken:(NSString *)pushToken
                                        voipToken:(nullable NSString *)voipToken
                                          success:(void (^)())successHandler
                                          failure:(void (^)(NSError *error))failureHandler
NS_SWIFT_NAME(registerForPushNotifications(pushToken:voipToken:success:failure:));

#endif

+ (void)unregisterTextSecureWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failureBlock;

@end

NS_ASSUME_NONNULL_END

