//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSSignalService.h"
#import "NSNotificationCenter+OWS.h"
#import "OWSCensorshipConfiguration.h"
#import "OWSHTTPSecurityPolicy.h"
#import "TSAccountManager.h"
#import "TSConstants.h"
#import "TSStorageManager.h"
#import <AFNetworking/AFHTTPSessionManager.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const kTSStorageManager_OWSSignalService = @"kTSStorageManager_OWSSignalService";
NSString *const kTSStorageManager_isCensorshipCircumventionManuallyActivated =
@"kTSStorageManager_isCensorshipCircumventionManuallyActivated";
NSString *const kTSStorageManager_ManualCensorshipCircumventionDomain =
@"kTSStorageManager_ManualCensorshipCircumventionDomain";
NSString *const kTSStorageManager_ManualCensorshipCircumventionCountryCode =
@"kTSStorageManager_ManualCensorshipCircumventionCountryCode";
static NSString *TextSecureServerURL = @"wss://token-chat-service.herokuapp.com";

NSString *const kNSNotificationName_IsCensorshipCircumventionActiveDidChange =
@"kNSNotificationName_IsCensorshipCircumventionActiveDidChange";

@interface OWSSignalService ()

@property (nonatomic, readonly) OWSCensorshipConfiguration *censorshipConfiguration;

@property (nonatomic) BOOL hasCensoredPhoneNumber;

@property (atomic) BOOL isCensorshipCircumventionActive;

@end

#pragma mark -

@implementation OWSSignalService

@synthesize isCensorshipCircumventionActive = _isCensorshipCircumventionActive;

+ (instancetype)sharedInstance
{
    static OWSSignalService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initDefault];
    });
    return sharedInstance;
}

- (instancetype)initDefault
{
    self = [super init];
    if (!self) {
        return self;
    }

    _censorshipConfiguration = [OWSCensorshipConfiguration new];

    [self observeNotifications];

    [self updateHasCensoredPhoneNumber];
    [self updateIsCensorshipCircumventionActive];

    OWSSingletonAssert();

    return self;
}

- (void)observeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationStateDidChange:)
                                                 name:kNSNotificationName_RegistrationStateDidChange
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(localNumberDidChange:)
                                                 name:kNSNotificationName_LocalNumberDidChange
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateHasCensoredPhoneNumber
{
    OWSAssert([NSThread isMainThread]);

    NSString *localNumber = [TSAccountManager localNumber];

    if (localNumber) {
        self.hasCensoredPhoneNumber = [self.censorshipConfiguration isCensoredPhoneNumber:localNumber];
    } else {
        DDLogError(@"%@ no known phone number to check for censorship.", self.tag);
        self.hasCensoredPhoneNumber = NO;
    }

    [self updateIsCensorshipCircumventionActive];
}

- (BOOL)isCensorshipCircumventionManuallyActivated
{
    return [[TSStorageManager sharedManager] boolForKey:kTSStorageManager_isCensorshipCircumventionManuallyActivated
                                           inCollection:kTSStorageManager_OWSSignalService];
}

- (void)setIsCensorshipCircumventionManuallyActivated:(BOOL)value
{
    OWSAssert([NSThread isMainThread]);

    [[TSStorageManager sharedManager] setObject:@(value)
                                         forKey:kTSStorageManager_isCensorshipCircumventionManuallyActivated
                                   inCollection:kTSStorageManager_OWSSignalService];

    [self updateIsCensorshipCircumventionActive];
}

- (void)updateIsCensorshipCircumventionActive
{
    OWSAssert([NSThread isMainThread]);

    self.isCensorshipCircumventionActive
    = (self.isCensorshipCircumventionManuallyActivated || self.hasCensoredPhoneNumber);
}

- (void)setIsCensorshipCircumventionActive:(BOOL)isCensorshipCircumventionActive
{
    OWSAssert([NSThread isMainThread]);

    @synchronized(self)
    {
        if (_isCensorshipCircumventionActive == isCensorshipCircumventionActive) {
            return;
        }

        _isCensorshipCircumventionActive = isCensorshipCircumventionActive;
    }

    [[NSNotificationCenter defaultCenter]
     postNotificationNameAsync:kNSNotificationName_IsCensorshipCircumventionActiveDidChange
     object:nil
     userInfo:nil];
}

- (BOOL)isCensorshipCircumventionActive
{
    @synchronized(self)
    {
        return _isCensorshipCircumventionActive;
    }
}

- (AFHTTPSessionManager *)signalServiceSessionManager
{
    if (self.isCensorshipCircumventionActive) {
        DDLogInfo(@"%@ using reflector HTTPSessionManager", self.tag);
        return self.reflectorSignalServiceSessionManager;
    } else {
        return self.defaultSignalServiceSessionManager;
    }
}

+ (void)setBaseURLPath:(NSString *)baseURLPath {
    TextSecureServerURL = baseURLPath;
}

+ (NSString *)baseURLPath {
    return TextSecureServerURL;
}

- (AFHTTPSessionManager *)defaultSignalServiceSessionManager
{
    NSURL *baseURL = [[NSURL alloc] initWithString:OWSSignalService.baseURLPath];
    OWSAssert(baseURL);
    NSURLSessionConfiguration *sessionConf = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    AFHTTPSessionManager *sessionManager =
    [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL sessionConfiguration:sessionConf];

    sessionManager.securityPolicy = [OWSHTTPSecurityPolicy sharedPolicy];
    sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];

    return sessionManager;
}

- (NSURL *)domainFrontingBaseURL
{
    NSString *localNumber = [TSAccountManager localNumber];
    OWSAssert(localNumber.length > 0);

    // Target fronting domain
    OWSAssert(self.isCensorshipCircumventionActive);
    NSString *frontingHost = [self.censorshipConfiguration frontingHost:localNumber];
    if (self.isCensorshipCircumventionManuallyActivated && self.manualCensorshipCircumventionDomain.length > 0) {
        frontingHost = self.manualCensorshipCircumventionDomain;
    };
    NSURL *baseURL = [[NSURL alloc] initWithString:[self.censorshipConfiguration frontingHost:localNumber]];
    OWSAssert(baseURL);

    return baseURL;
}

- (AFHTTPSessionManager *)reflectorSignalServiceSessionManager
{
    NSURLSessionConfiguration *sessionConf = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    AFHTTPSessionManager *sessionManager =
    [[AFHTTPSessionManager alloc] initWithBaseURL:self.domainFrontingBaseURL sessionConfiguration:sessionConf];

    sessionManager.securityPolicy = [[self class] googlePinningPolicy];

    sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [sessionManager.requestSerializer setValue:self.censorshipConfiguration.signalServiceReflectorHost forHTTPHeaderField:@"Host"];

    sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];

    return sessionManager;
}

#pragma mark - Profile Uploading

- (AFHTTPSessionManager *)CDNSessionManager
{
    if (self.isCensorshipCircumventionActive) {
        DDLogInfo(@"%@ using reflector CDNSessionManager", self.tag);
        return self.reflectorCDNSessionManager;
    } else {
        return self.defaultCDNSessionManager;
    }
}

- (AFHTTPSessionManager *)defaultCDNSessionManager
{
    NSURL *baseURL = [[NSURL alloc] initWithString:textSecureCDNServerURL];
    OWSAssert(baseURL);

    NSURLSessionConfiguration *sessionConf = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    AFHTTPSessionManager *sessionManager =
    [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL sessionConfiguration:sessionConf];

    sessionManager.securityPolicy = [OWSHTTPSecurityPolicy sharedPolicy];

    // Default acceptable content headers are rejected by AWS
    sessionManager.responseSerializer.acceptableContentTypes = nil;

    return sessionManager;
}

- (AFHTTPSessionManager *)reflectorCDNSessionManager
{
    NSURLSessionConfiguration *sessionConf = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    AFHTTPSessionManager *sessionManager =
    [[AFHTTPSessionManager alloc] initWithBaseURL:self.domainFrontingBaseURL sessionConfiguration:sessionConf];

    sessionManager.securityPolicy = [[self class] googlePinningPolicy];

    sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [sessionManager.requestSerializer setValue:self.censorshipConfiguration.CDNReflectorHost forHTTPHeaderField:@"Host"];

    sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];

    return sessionManager;
}

#pragma mark - Google Pinning Policy

/**
 * We use the Google Pinning Policy when connecting to our censorship circumventing reflector,
 * which is hosted on Google.
 */
+ (AFSecurityPolicy *)googlePinningPolicy {
    static AFSecurityPolicy *securityPolicy = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        NSString *path = [NSBundle.mainBundle pathForResource:@"GIAG2" ofType:@"crt"];

        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            @throw [NSException
                    exceptionWithName:@"Missing server certificate"
                    reason:[NSString stringWithFormat:@"Missing signing certificate for service googlePinningPolicy"]
                    userInfo:nil];
        }

        NSData *googleCertData = [NSData dataWithContentsOfFile:path options:0 error:&error];
        if (!googleCertData) {
            if (error) {
                @throw [NSException exceptionWithName:@"OWSSignalServiceHTTPSecurityPolicy" reason:@"Couln't read google pinning cert" userInfo:nil];
            } else {
                NSString *reason = [NSString stringWithFormat:@"Reading google pinning cert faile with error: %@", error];
                @throw [NSException exceptionWithName:@"OWSSignalServiceHTTPSecurityPolicy" reason:reason userInfo:nil];
            }
        }

        NSSet<NSData *> *certificates = [NSSet setWithObject:googleCertData];
        securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:certificates];
    });
    return securityPolicy;
}

#pragma mark - Events

- (void)registrationStateDidChange:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateHasCensoredPhoneNumber];
    });
}

- (void)localNumberDidChange:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateHasCensoredPhoneNumber];
    });
}

#pragma mark - Manual Censorship Circumvention

- (NSString *)manualCensorshipCircumventionDomain
{
    return [[TSStorageManager sharedManager] objectForKey:kTSStorageManager_ManualCensorshipCircumventionDomain
                                             inCollection:kTSStorageManager_OWSSignalService];
}

- (void)setManualCensorshipCircumventionDomain:(NSString *)value
{
    OWSAssert([NSThread isMainThread]);

    [[TSStorageManager sharedManager] setObject:value
                                         forKey:kTSStorageManager_ManualCensorshipCircumventionDomain
                                   inCollection:kTSStorageManager_OWSSignalService];
}

- (NSString *)manualCensorshipCircumventionCountryCode
{
    OWSAssert([NSThread isMainThread]);

    return [[TSStorageManager sharedManager] objectForKey:kTSStorageManager_ManualCensorshipCircumventionCountryCode
                                             inCollection:kTSStorageManager_OWSSignalService];
}

- (void)setManualCensorshipCircumventionCountryCode:(NSString *)value
{
    OWSAssert([NSThread isMainThread]);

    [[TSStorageManager sharedManager] setObject:value
                                         forKey:kTSStorageManager_ManualCensorshipCircumventionCountryCode
                                   inCollection:kTSStorageManager_OWSSignalService];
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

