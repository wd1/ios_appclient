//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "ProfileManager.h"
#import <SignalServiceKit/Cryptography.h>
#import <SignalServiceKit/NSData+Image.h>
#import <SignalServiceKit/NSData+hexString.h>
#import <SignalServiceKit/NSDate+OWS.h>
#import <SignalServiceKit/NSNotificationCenter+OWS.h>
#import <SignalServiceKit/OWSMessageSender.h>
#import <SignalServiceKit/OWSRequestBuilder.h>
#import <SignalServiceKit/SecurityUtils.h>
#import <SignalServiceKit/TSAccountManager.h>
#import <SignalServiceKit/TSGroupThread.h>
#import <SignalServiceKit/TSProfileAvatarUploadFormRequest.h>
#import <SignalServiceKit/TSStorageManager.h>
#import <SignalServiceKit/TSThread.h>
#import <SignalServiceKit/TSYapDatabaseObject.h>
#import <SignalServiceKit/TextSecureKitEnv.h>
#import <SignalServiceKit/Asserts.h>
#import <SignalServiceKit/TSNetworkManager.h>
#import <SignalServiceKit/OWSIdentityManager.h>
#import <SignalServiceKit/OWSSignalService.h>
#import "NSString+OWS.h"

NS_ASSUME_NONNULL_BEGIN

// UserProfile properties may be read from any thread, but should
// only be mutated when synchronized on the profile manager.
@interface UserProfile : TSYapDatabaseObject

@property (atomic, readonly) NSString *recipientId;
@property (atomic, nullable) OWSAES256Key *profileKey;
@property (atomic, nullable) NSString *profileName;
@property (atomic, nullable) NSString *avatarUrlPath;
@property (atomic, nullable) NSString *avatarFileName;

@property (atomic, nullable) NSDate *lastUpdateDate;

- (instancetype)init NS_UNAVAILABLE;

@end

#pragma mark -

@implementation UserProfile

@synthesize profileName = _profileName;

- (instancetype)initWithRecipientId:(NSString *)recipientId
{
    self = [super initWithUniqueId:recipientId];

    if (self) {
        _recipientId = recipientId;
    }

    return self;
}

- (nullable NSString *)profileName
{
    @synchronized(self)
    {
        return _profileName;
    }
}

- (void)setProfileName:(nullable NSString *)profileName
{
    @synchronized(self)
    {
        _profileName = [profileName ows_stripped];
    }
}

@end

#pragma mark -

NSString *const kLocalProfileUniqueId = @"kLocalProfileUniqueId";

NSString *const kOWSProfileManager_UserWhitelistCollection = @"kOWSProfileManager_UserWhitelistCollection";
NSString *const kOWSProfileManager_GroupWhitelistCollection = @"kOWSProfileManager_GroupWhitelistCollection";

// The max bytes for a user's profile name, encoded in UTF8.
// Before encrypting and submitting we NULL pad the name data to this length.
const NSUInteger kOWSProfileManager_NameDataLength = 26;

@interface ProfileManager ()

@property (nonatomic, readonly) OWSMessageSender *messageSender;
@property (nonatomic, readonly) YapDatabaseConnection *dbConnection;
@property (nonatomic, readonly) TSNetworkManager *networkManager;
@property (nonatomic, readonly) OWSIdentityManager *identityManager;
@property (nonatomic, readonly) UserProfile *localUserProfile;
@property (atomic, readonly) NSMutableDictionary<NSString *, NSNumber *> *userProfileWhitelistCache;
@property (atomic, readonly) NSMutableDictionary<NSString *, NSNumber *> *groupProfileWhitelistCache;

@end

#pragma mark -

@implementation ProfileManager

@synthesize localUserProfile = _localUserProfile;

+ (instancetype)sharedManager
{
    static ProfileManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });

    return sharedMyManager;
}

- (instancetype)initDefault
{
    TSStorageManager *storageManager = [TSStorageManager sharedManager];
    OWSMessageSender *messageSender = [TextSecureKitEnv sharedEnv].messageSender;
    TSNetworkManager *networkManager = [TSNetworkManager sharedManager];

    return [self initWithStorageManager:storageManager messageSender:messageSender networkManager:networkManager];
}

- (instancetype)initWithStorageManager:(TSStorageManager *)storageManager
                         messageSender:(OWSMessageSender *)messageSender
                        networkManager:(TSNetworkManager *)networkManager
{
    self = [super init];

    if (self) {
        _messageSender = messageSender;
        _dbConnection = storageManager.newDatabaseConnection;
        _networkManager = networkManager;

        _userProfileWhitelistCache = [NSMutableDictionary new];
        _groupProfileWhitelistCache = [NSMutableDictionary new];
    }

    return self;
}

- (OWSIdentityManager *)identityManager
{
    return [OWSIdentityManager sharedManager];
}

#pragma mark - User Profile Accessor

// This method can be safely called from any thread.
- (UserProfile *)getOrBuildUserProfileForRecipientId:(NSString *)recipientId
{
    __block UserProfile *instance;
    // Make sure to read on the local db connection for consistency.
    [self.dbConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        instance = [UserProfile fetchObjectWithUniqueID:recipientId transaction:transaction];
    }];

    if (!instance) {
        instance = [[UserProfile alloc] initWithRecipientId:recipientId];
    }

    return instance;
}

- (void)saveUserProfile:(UserProfile *)userProfile
{
    // Make a copy to use inside the transaction.
    // To avoid deadlock, we want to avoid creating a new transaction while sync'd on self.
    UserProfile *userProfileCopy;
    @synchronized(self)
    {
        userProfileCopy = [userProfile copy];
        // Other threads may modify this profile's properties
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Make sure to save on the local db connection for consistency.
        [self.dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [userProfileCopy saveWithTransaction:transaction];
        }];
    });
}

#pragma mark - Local Profile

- (UserProfile *)localUserProfile
{
    @synchronized(self)
    {
        if (_localUserProfile == nil) {
            // Make sure to read on the local db connection for consistency.
            [self.dbConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                _localUserProfile = [UserProfile fetchObjectWithUniqueID:kLocalProfileUniqueId transaction:transaction];
            }];

            if (_localUserProfile == nil) {
                _localUserProfile = [[UserProfile alloc] initWithRecipientId:kLocalProfileUniqueId];
                _localUserProfile.profileKey = [OWSAES256Key generateRandomKey];

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self saveUserProfile:_localUserProfile];
                });
            }
        }

        return _localUserProfile;
    }
}

- (OWSAES256Key *)localProfileKey
{
    @synchronized(self)
    {
        return self.localUserProfile.profileKey;
    }
}

#pragma mark - Profile Whitelist

- (void)addUserToProfileWhitelist:(NSString *)recipientId
{
    [self addUsersToProfileWhitelist:@[ recipientId ]];
}

- (void)addUsersToProfileWhitelist:(NSArray<NSString *> *)recipientIds
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray<NSString *> *newRecipientIds = [NSMutableArray new];

        @synchronized(self)
        {
            for (NSString *recipientId in recipientIds) {
                if (![self isUserInProfileWhitelist:recipientId]) {
                    [newRecipientIds addObject:recipientId];
                }
            }

            if (newRecipientIds.count < 1) {
                return;
            }

            for (NSString *recipientId in recipientIds) {
                self.userProfileWhitelistCache[recipientId] = @(YES);
            }
        }

        [self.dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            for (NSString *recipientId in recipientIds) {
                [transaction setObject:@(YES)
                                forKey:recipientId
                          inCollection:kOWSProfileManager_UserWhitelistCollection];
            }
        }];
    });
}

- (BOOL)isUserInProfileWhitelist:(NSString *)recipientId
{
    @synchronized(self)
    {
        NSNumber *_Nullable value = self.userProfileWhitelistCache[recipientId];
        if (value) {
            return [value boolValue];
        }

        value =
        @([self.dbConnection hasObjectForKey:recipientId inCollection:kOWSProfileManager_UserWhitelistCollection]);
        self.userProfileWhitelistCache[recipientId] = value;
        return [value boolValue];
    }
}

- (void)addGroupIdToProfileWhitelist:(NSData *)groupId
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *groupIdKey = [groupId hexadecimalString];

        @synchronized(self)
        {
            if ([self isGroupIdInProfileWhitelist:groupId]) {
                return;
            }

            self.groupProfileWhitelistCache[groupIdKey] = @(YES);
        }

        [self.dbConnection setBool:YES forKey:groupIdKey inCollection:kOWSProfileManager_GroupWhitelistCollection];
    });
}

- (BOOL)isGroupIdInProfileWhitelist:(NSData *)groupId
{
    @synchronized(self)
    {
        NSString *groupIdKey = [groupId hexadecimalString];
        NSNumber *_Nullable value = self.groupProfileWhitelistCache[groupIdKey];
        if (value) {
            return [value boolValue];
        }

        value = @(nil !=
        [self.dbConnection objectForKey:groupIdKey inCollection:kOWSProfileManager_GroupWhitelistCollection]);
        self.groupProfileWhitelistCache[groupIdKey] = value;
        return [value boolValue];
    }
}

- (void)addThreadToProfileWhitelist:(TSThread *)thread
{
    if (thread.isGroupThread) {
        TSGroupThread *groupThread = (TSGroupThread *)thread;
        NSData *groupId = groupThread.groupModel.groupId;
        [self addGroupIdToProfileWhitelist:groupId];

        // When we add a group to the profile whitelist, we might as well
        // also add all current members to the profile whitelist
        // individually as well just in case delivery of the profile key
        // fails.
        for (NSString *recipientId in groupThread.recipientIdentifiers) {
            [self addUserToProfileWhitelist:recipientId];
        }
    } else {
        NSString *recipientId = thread.contactIdentifier;
        [self addUserToProfileWhitelist:recipientId];
    }
}

- (BOOL)isThreadInProfileWhitelist:(TSThread *)thread
{
    if (thread.isGroupThread) {
        TSGroupThread *groupThread = (TSGroupThread *)thread;
        NSData *groupId = groupThread.groupModel.groupId;
        return [self isGroupIdInProfileWhitelist:groupId];
    } else {
        NSString *recipientId = thread.contactIdentifier;
        return [self isUserInProfileWhitelist:recipientId];
    }
}

- (void)setContactRecipientIds:(NSArray<NSString *> *)contactRecipientIds
{
    [self addUsersToProfileWhitelist:contactRecipientIds];
}

#pragma mark - Other User's Profiles

- (void)setProfileKeyData:(NSData *)profileKeyData forRecipientId:(NSString *)recipientId;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized(self)
        {
            OWSAES256Key *_Nullable profileKey = [OWSAES256Key keyWithData:profileKeyData];
            if (profileKey == nil) {
                return;
            }

            UserProfile *userProfile = [self getOrBuildUserProfileForRecipientId:recipientId];

            if (userProfile.profileKey && [userProfile.profileKey.keyData isEqual:profileKey.keyData]) {
                // Ignore redundant update.
                return;
            }

            userProfile.profileKey = profileKey;

            // Clear profile state.
            userProfile.profileName = nil;
            userProfile.avatarUrlPath = nil;
            userProfile.avatarFileName = nil;

            [self saveUserProfile:userProfile];
        }
    });
}

- (nullable NSData *)profileKeyDataForRecipientId:(NSString *)recipientId
{
    return [self profileKeyForRecipientId:recipientId].keyData;
}

- (nullable OWSAES256Key *)profileKeyForRecipientId:(NSString *)recipientId
{
    @synchronized(self)
    {
        UserProfile *userProfile = [self getOrBuildUserProfileForRecipientId:recipientId];

        return userProfile.profileKey;
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

