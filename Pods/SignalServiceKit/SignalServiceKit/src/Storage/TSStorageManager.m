//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSStorageManager.h"
#import "NSData+Base64.h"
#import "OWSAnalytics.h"
#import "OWSDisappearingMessagesFinder.h"
#import "OWSFailedAttachmentDownloadsJob.h"
#import "OWSFailedMessagesJob.h"
#import "OWSIncomingMessageFinder.h"
#import "SignalRecipient.h"
#import "TSAttachmentStream.h"
#import "TSDatabaseSecondaryIndexes.h"
#import "TSDatabaseView.h"
#import "TSInteraction.h"
#import "TSThread.h"
#import <25519/Randomness.h>
#import "TSAccountManager.h"
#import <SAMKeychain/SAMKeychain.h>
#import <SignalServiceKit/OWSBatchMessageProcessor.h>
#import <SignalServiceKit/OWSMessageReceiver.h>
#import <YapDatabase/YapDatabaseRelationship.h>
#import <YapDatabase/YapDatabaseManager.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const TSStorageManagerExceptionNameDatabasePasswordInaccessible = @"TSStorageManagerExceptionNameDatabasePasswordInaccessible";
NSString *const TSStorageManagerExceptionNameDatabasePasswordInaccessibleWhileBackgrounded =
@"TSStorageManagerExceptionNameDatabasePasswordInaccessibleWhileBackgrounded";
NSString *const TSStorageManagerExceptionNameDatabasePasswordUnwritable = @"TSStorageManagerExceptionNameDatabasePasswordUnwritable";
NSString *const TSStorageManagerExceptionNameNoDatabase = @"TSStorageManagerExceptionNameNoDatabase";

static const NSString *const databaseName = @"Signal.sqlite";
static const NSString *const keysDBName = @"SignalKeys.sqlite";
static NSString *keychainService          = @"TSKeyChainService";
static NSString *keychainDBPassAccount    = @"TSDatabasePass";

#pragma mark -

// This flag is only used in DEBUG builds.
static BOOL isDatabaseInitializedFlag = NO;

NSObject *isDatabaseInitializedFlagLock()
{
    static NSObject *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [NSObject new];
    });
    return instance;
}

BOOL isDatabaseInitialized()
{
    @synchronized(isDatabaseInitializedFlagLock())
    {
        return isDatabaseInitializedFlag;
    }
}

void setDatabaseInitialized()
{
    @synchronized(isDatabaseInitializedFlagLock())
    {
        isDatabaseInitializedFlag = YES;
    }
}

#pragma mark -

@interface YapDatabaseConnection ()

- (id)initWithDatabase:(YapDatabase *)inDatabase;

@end

#pragma mark -

// This class is only used in DEBUG builds.
@interface OWSDatabaseConnection : YapDatabaseConnection

@end

#pragma mark -

@implementation OWSDatabaseConnection

// This clobbers the superclass implementation to include an assert which
// ensures that the database is in a ready state before creating write transactions.
//
// Creating write transactions before the _sync_ database views are registered
// causes YapDatabase to rebuild all of our database views, which is catastrophic.
// We're not sure why, but it causes YDB's "view version" checks to fail.
- (void)readWriteWithBlock:(void (^)(YapDatabaseReadWriteTransaction *transaction))block
{
    OWSAssert(isDatabaseInitialized());

    [super readWriteWithBlock:block];
}

@end

#pragma mark -

// This class is only used in DEBUG builds.
@interface YapDatabase ()

- (void)addConnection:(YapDatabaseConnection *)connection;

@end

#pragma mark -

@interface OWSDatabase : YapDatabase

@end

#pragma mark -

@implementation OWSDatabase

// This clobbers the superclass implementation to include asserts which
// ensure that the database is in a ready state before creating write transactions.
//
// See comments in OWSDatabaseConnection.
- (YapDatabaseConnection *)newConnection
{
    YapDatabaseConnection *connection = [[OWSDatabaseConnection alloc] initWithDatabase:self];

    [self addConnection:connection];
    return connection;
}

@end

#pragma mark -

@interface TSStorageManager ()

@property (nullable, atomic) YapDatabase *database;
@property (nullable, atomic) YapDatabase *keysDatabase;

@property (nonatomic, copy) NSString *accountName;

@end

#pragma mark -

// Some lingering TSRecipient records in the wild causing crashes.
// This is a stop gap until a proper cleanup happens.
@interface TSRecipient : NSObject <NSCoding>

@end

#pragma mark -

@interface OWSUnknownObject : NSObject <NSCoding>

@end

#pragma mark -

/**
 * A default object to return when we can't deserialize an object from YapDB. This can prevent crashes when
 * old objects linger after their definition file is removed. The danger is that, the objects can lay in wait
 * until the next time a DB extension is added and we necessarily enumerate the entire DB.
 */
@implementation OWSUnknownObject

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

}

@end

#pragma mark -

@interface OWSUnarchiverDelegate : NSObject <NSKeyedUnarchiverDelegate>

@end

#pragma mark -

@implementation OWSUnarchiverDelegate

- (nullable Class)unarchiver:(NSKeyedUnarchiver *)unarchiver cannotDecodeObjectOfClassName:(NSString *)name originalClasses:(NSArray<NSString *> *)classNames
{
    DDLogError(@"%@ Could not decode object: %@", self.tag, name);
    OWSProdError([OWSAnalyticsEvents storageErrorCouldNotDecodeClass]);
    return [OWSUnknownObject class];
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

#pragma mark -

@implementation TSStorageManager

+ (instancetype)sharedManager {
    static TSStorageManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
#if TARGET_OS_IPHONE
        [sharedManager protectSignalFiles];
#endif
    });
    return sharedManager;
}

- (int)getOrGenerateResortID
{
    int resortID = [[_keysDBReadConnection objectForKey:@"ResortID"
                                           inCollection:TSStorageUserAccountCollection] unsignedIntValue];

    if (resortID == 0) {
        resortID = (uint32_t)arc4random_uniform(16380) + 1; //5687
        DDLogWarn(@"%@ Generated a new registrationID: %u", self.tag, resortID);

        [_keysDBReadConnection setObject:[NSNumber numberWithUnsignedInteger:resortID]
                                  forKey:@"ResortID"
                            inCollection:TSStorageUserAccountCollection];
    }

    return resortID;
}

- (NSString *)backupDatabasePath
{
    return [[self backupDirectoryPath] stringByAppendingFormat:@"/Signal-%@.sqlite", self.accountName];
}

- (void)__deleteFileIfNeededAtPath:(NSString *)path
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

- (void)loadBackupIfNeeded
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self backupDatabasePath]]) {

        NSString *databasePath = [self dbPathWithName:databaseName];
        NSString *walFilePath = [databasePath stringByAppendingString:@"-wal"];
        NSString *shmFilePath = [databasePath stringByAppendingString:@"-shm"];

        [self __deleteFileIfNeededAtPath:walFilePath];
        [self __deleteFileIfNeededAtPath:shmFilePath];

        NSError *error;
        [[NSFileManager defaultManager] moveItemAtPath:[self backupDatabasePath] toPath:databasePath error:&error];

        if (error) {
            DDLogError(@"Error moving backed up db file: %@", error.localizedDescription);
        }
    }
}

- (BOOL)tryToLoadDatabase
{
    if (!self.accountName) {
        DDLogError(@"You can't use without account name !!!");

        return NO;
    }

    [self loadBackupIfNeeded];

    // We determine the database password first, since a side effect of
    // this can be deleting any existing database file (if we're recovering
    // from a corrupt keychain).

    [self prepareDatabasePasswordIfNeededForKey:self.accountName];

    YapDatabaseOptions *options = [[YapDatabaseOptions alloc] init];
    options.corruptAction       = YapDatabaseCorruptAction_Fail;

    __weak typeof (self)weakSelf = self;
    options.cipherKeyBlock = ^{
        typeof(self)strongSelf = weakSelf;
        return [strongSelf databasePasswordForKey:strongSelf.accountName];
    };

    _database = [[YapDatabase alloc] initWithPath:[self dbPathWithName:databaseName]
                                       serializer:NULL
                                     deserializer:[[self class] logOnFailureDeserializer]
                                          options:options];
    if (!_database) {

        // in case the user has used "keychainService" service for retrieving password
        options.cipherKeyBlock = ^{
            typeof(self)strongSelf = weakSelf;
            return [strongSelf databasePasswordForKey:keychainService];
        };

        _database = [[YapDatabase alloc] initWithPath:[self dbPathWithName:databaseName]
                                           serializer:NULL
                                         deserializer:[[self class] logOnFailureDeserializer]
                                              options:options];

        if (!_database) {
            return NO;
        } else {
            NSError *keyFetchError;
            NSString *previousVersionDBPassword = [SAMKeychain passwordForService:keychainService account:keychainDBPassAccount error:&keyFetchError];
            if (previousVersionDBPassword) {

                NSError *error;
                [SAMKeychain setPassword:previousVersionDBPassword forService:self.accountName account:keychainDBPassAccount error:&error];
            }
        }
    }

    _dbReadConnection = self.newDatabaseConnection;
    _dbReadWriteConnection = self.newDatabaseConnection;

    YapDatabaseOptions *keysDBOptions = [[YapDatabaseOptions alloc] init];
    keysDBOptions.corruptAction       = YapDatabaseCorruptAction_Fail;

    keysDBOptions.cipherKeyBlock = ^{
        typeof(self)strongSelf = weakSelf;
        return [strongSelf databasePasswordForKey:strongSelf.accountName];
    };

    _keysDatabase = [[YapDatabase alloc] initWithPath:[self dbPathWithName:keysDBName]
                                           serializer:NULL
                                         deserializer:[[self class] logOnFailureDeserializer]
                                              options:keysDBOptions];
    _keysDatabase.defaultObjectCacheEnabled = NO;

    if (!_keysDatabase) {
        return NO;
    }

    _keysDBReadConnection = self.newKeysDatabaseConnection;
    _keysDBReadWriteConnection = self.newKeysDatabaseConnection;

    return YES;
}

- (nullable NSString *)corruptedChatDBFilePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSURL *fileURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *path = [fileURL path];

    NSString *dbPath = [self dbPathWithName:databaseName];
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];

    NSString *corruptedDBFilePath;
    NSString *corruptedDBFile = [[dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.corrupt'"]] firstObject];

    if (corruptedDBFile) {
        corruptedDBFilePath = [path stringByAppendingPathComponent:corruptedDBFile];
    }

    return corruptedDBFilePath;
}

/**
 * NSCoding sometimes throws exceptions killing our app. We want to log that exception.
 **/
+ (YapDatabaseDeserializer)logOnFailureDeserializer
{
    OWSUnarchiverDelegate *unarchiverDelegate = [OWSUnarchiverDelegate new];

    return ^id(NSString __unused *collection, NSString __unused *key, NSData *data) {
        if (!data || data.length <= 0) {
            return nil;
        }

        @try {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            unarchiver.delegate = unarchiverDelegate;
            return [unarchiver decodeObjectForKey:@"root"];
        } @catch (NSException *exception) {
            // Sync log in case we bail.
            OWSProdError([OWSAnalyticsEvents storageErrorDeserialization]);
            @throw exception;
        }
    };
}

- (void)setupForAccountName:(NSString *)accountName isFirstLaunch:(BOOL)isFirstLaunch
{
    self.accountName = [accountName copy];

    if (isFirstLaunch) {

        NSError *keyFetchError;
        NSString *previousVersionDBPassword = [SAMKeychain passwordForService:keychainService account:keychainDBPassAccount error:&keyFetchError];
        if (previousVersionDBPassword) {

            NSError *error;
            [SAMKeychain setPassword:previousVersionDBPassword forService:self.accountName account:keychainDBPassAccount error:&error];
        }
    }

    [self setupDatabaseWithSafeBlockingMigrations:^{

    }];
}

- (NSString *)backupDirectoryPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]lastObject];

    return [[documentsURL path] stringByAppendingFormat:@"/%@", @"Backup"];
}

- (void)createBackupDirectoryIfNeeded
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *backupDirectoryPath = [self backupDirectoryPath];

    if (![fileManager fileExistsAtPath:backupDirectoryPath]) {
        NSError *error;
        [fileManager createDirectoryAtPath:backupDirectoryPath withIntermediateDirectories:NO attributes:nil error:&error];
    }
}

- (void)setupDatabaseWithSafeBlockingMigrations:(void (^_Nonnull)())safeBlockingMigrationsBlock
{
    [self createBackupDirectoryIfNeeded];
    [self tryToLoadDatabase];

    // Synchronously register extensions which are essential for views.
    [TSDatabaseView registerThreadInteractionsDatabaseView];
    [TSDatabaseView registerThreadDatabaseView];
    [TSDatabaseView registerUnreadDatabaseView];
    [self.database registerExtension:[TSDatabaseSecondaryIndexes registerTimeStampIndex] withName:@"idx"];
    [OWSMessageReceiver syncRegisterDatabaseExtension:self.database];
    [OWSBatchMessageProcessor syncRegisterDatabaseExtension:self.database];

    // See comments on OWSDatabaseConnection.
    //
    // In the absence of finding documentation that can shed light on the issue we've been
    // seeing, this issue only seems to affect sync and not async registrations.  We've always
    // been opening write transactions before the async registrations complete without negative
    // consequences.
    setDatabaseInitialized();

    // Run the blocking migrations.
    //
    // These need to run _before_ the async registered database views or
    // they will block on them, which (in the upgrade case) can block
    // return of appDidFinishLaunching... which in term can cause the
    // app to crash on launch.
    safeBlockingMigrationsBlock();

    // Asynchronously register other extensions.
    //
    // All sync registrations must be done before all async registrations,
    // or the sync registrations will block on the async registrations.
    [TSDatabaseView asyncRegisterUnseenDatabaseView];
    [TSDatabaseView asyncRegisterThreadOutgoingMessagesDatabaseView];
    [TSDatabaseView asyncRegisterThreadSpecialMessagesDatabaseView];

    // Register extensions which aren't essential for rendering threads async.
    [[OWSIncomingMessageFinder new] asyncRegisterExtension];
    [TSDatabaseView asyncRegisterSecondaryDevicesDatabaseView];
    [OWSDisappearingMessagesFinder asyncRegisterDatabaseExtensions:self];
    OWSFailedMessagesJob *failedMessagesJob = [[OWSFailedMessagesJob alloc] initWithStorageManager:self];
    [failedMessagesJob asyncRegisterDatabaseExtensions];
    OWSFailedAttachmentDownloadsJob *failedAttachmentDownloadsMessagesJob =
    [[OWSFailedAttachmentDownloadsJob alloc] initWithStorageManager:self];
    [failedAttachmentDownloadsMessagesJob asyncRegisterDatabaseExtensions];

    // NOTE: [TSDatabaseView asyncRegistrationCompletion] ensures that
    // kNSNotificationName_DatabaseViewRegistrationComplete is not fired until all
    // of the async registrations are complete.
    [TSDatabaseView asyncRegistrationCompletion];
}

- (void)protectSignalFiles {
    [self protectFolderAtPath:[TSAttachmentStream attachmentsFolder]];

    NSString *databasePath = [self dbPathWithName:databaseName];
    [self protectFolderAtPath:databasePath];
    [self protectFolderAtPath:[databasePath stringByAppendingString:@"-shm"]];
    [self protectFolderAtPath:[databasePath stringByAppendingString:@"-wal"]];

    NSString *keysDBPath = [self dbPathWithName:keysDBName];
    [self protectFolderAtPath:keysDBPath];
    [self protectFolderAtPath:[keysDBPath stringByAppendingString:@"-shm"]];
    [self protectFolderAtPath:[keysDBPath stringByAppendingString:@"-wal"]];
}

- (void)protectFolderAtPath:(NSString *)path {
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) {
        return;
    }

    NSError *error;
    NSDictionary *fileProtection = @{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication};
    [[NSFileManager defaultManager] setAttributes:fileProtection ofItemAtPath:path error:&error];

    NSDictionary *resourcesAttrs = @{ NSURLIsExcludedFromBackupKey : @YES };

    NSURL *ressourceURL = [NSURL fileURLWithPath:path];
    BOOL success        = [ressourceURL setResourceValues:resourcesAttrs error:&error];

    if (error || !success) {
        OWSProdCritical([OWSAnalyticsEvents storageErrorFileProtection]);
    }
}

- (nullable YapDatabaseConnection *)newDatabaseConnection
{
    return self.database.newConnection;
}

- (nullable YapDatabaseConnection *)newKeysDatabaseConnection
{
    return self.keysDatabase.newConnection;
}

- (BOOL)userSetPassword {
    return FALSE;
}

- (BOOL)dbExists {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self dbPathWithName:databaseName]];
}

- (NSString *)dbPathWithName:(NSString *)name {
    NSString *databasePath;

    NSFileManager *fileManager = [NSFileManager defaultManager];
#if TARGET_OS_IPHONE
    NSURL *fileURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *path = [fileURL path];
    databasePath = [path stringByAppendingPathComponent:name];
#elif TARGET_OS_MAC

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSArray *urlPaths  = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];

    NSURL *appDirectory = [[urlPaths objectAtIndex:0] URLByAppendingPathComponent:bundleID isDirectory:YES];

    if (![fileManager fileExistsAtPath:[appDirectory path]]) {
        [fileManager createDirectoryAtURL:appDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }

    databasePath = [appDirectory.filePathURL.absoluteString stringByAppendingPathComponent:databaseName];
#endif

    return databasePath;
}

+ (BOOL)isDatabasePasswordAccessible
{
    [SAMKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
    NSError *error;
    NSString *dbPassword = [SAMKeychain passwordForService:keychainService account:keychainDBPassAccount error:&error];

    if (dbPassword && !error) {
        return YES;
    }

    if (error) {
        DDLogWarn(@"Database password couldn't be accessed: %@", error.localizedDescription);
    }

    return NO;
}

- (void)backgroundedAppDatabasePasswordInaccessibleWithErrorDescription:(NSString *)errorDescription
{
    OWSAssert([UIApplication sharedApplication].applicationState == UIApplicationStateBackground);

    // Sleep to give analytics events time to be delivered.
    [NSThread sleepForTimeInterval:5.0f];

    // Presumably this happened in response to a push notification. It's possible that the keychain is corrupted
    // but it could also just be that the user hasn't yet unlocked their device since our password is
    // kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    [NSException raise:TSStorageManagerExceptionNameDatabasePasswordInaccessibleWhileBackgrounded
                format:@"%@", errorDescription];
}

- (void)prepareDatabasePasswordIfNeededForKey:(NSString *)key
{
    [SAMKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];

    NSError *keyFetchError;
    NSString *dbPassword =
    [SAMKeychain passwordForService:key account:keychainDBPassAccount error:&keyFetchError];

    if (keyFetchError) {
        [self createAndSetNewDatabasePasswordForKey:key];
    }
}

- (NSData *)databasePasswordForKey:(NSString *)key
{
    [SAMKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];

    NSError *keyFetchError;
    NSString *dbPassword =
    [SAMKeychain passwordForService:key account:keychainDBPassAccount error:&keyFetchError];

    if (keyFetchError) {
        UIApplicationState applicationState = [UIApplication sharedApplication].applicationState;
        NSString *errorDescription = [NSString stringWithFormat:@"Database password inaccessible. No unlock since device restart? Error: %@ ApplicationState: %d", keyFetchError, (int)applicationState];
        DDLogError(@"%@ %@", self.tag, errorDescription);
        [DDLog flushLog];

        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            // TODO: Rather than crash here, we should detect the situation earlier
            // and exit gracefully - (in the app delegate?). See the `
            // This is a last ditch effort to avoid blowing away the user's database.
            [self backgroundedAppDatabasePasswordInaccessibleWithErrorDescription:errorDescription];
        }

        // At this point, either this is a new install so there's no existing password to retrieve
        // or the keychain has become corrupt.  Either way, we want to get back to a
        // "known good state" and behave like a new install.

        BOOL shouldHavePassword = [NSFileManager.defaultManager fileExistsAtPath:[self dbPathWithName:databaseName]];
        if (shouldHavePassword) {
            OWSProdCritical([OWSAnalyticsEvents storageErrorCouldNotLoadDatabaseSecondAttempt]);
        }

        // Try to reset app by deleting database.
        [self resetSignalStorageWithBackup:NO];

        dbPassword = [self createAndSetNewDatabasePasswordForKey:key];
    }

    return [dbPassword dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)createAndSetNewDatabasePasswordForKey:(NSString *)key
{
    NSString *newDBPassword = [[Randomness generateRandomBytes:30] base64EncodedString];
    NSError *keySetError;
    [SAMKeychain setPassword:newDBPassword forService:key account:keychainDBPassAccount error:&keySetError];
    if (keySetError) {
        OWSProdCritical([OWSAnalyticsEvents storageErrorCouldNotStoreDatabasePassword]);

        [self deletePasswordFromKeychainForKey:key];

        // Sleep to give analytics events time to be delivered.
        [NSThread sleepForTimeInterval:15.0f];

        [NSException raise:TSStorageManagerExceptionNameDatabasePasswordUnwritable
                    format:@"Setting DB password failed with error: %@", keySetError];
    } else {
        DDLogWarn(@"Succesfully set new DB password.");
    }

    return newDBPassword;
}

#pragma mark - convenience methods

- (void)setObject:(id)object forKey:(NSString *)key inCollection:(NSString *)collection {
    [self.dbReadWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:object forKey:key inCollection:collection];
    }];
}

- (void)setKeysObject:(id)object forKey:(NSString *)key inCollection:(NSString *)collection {
    [self.keysDBReadWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:object forKey:key inCollection:collection];
    }];
}

- (void)removeObjectForKey:(NSString *)string inCollection:(NSString *)collection {
    [self.dbReadWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:string inCollection:collection];
    }];
}

- (void)removeKeysObjectForKey:(NSString *)string inCollection:(NSString *)collection {
    [self.keysDBReadWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:string inCollection:collection];
    }];
}

- (id)objectForKey:(NSString *)key inCollection:(NSString *)collection {
    __block NSString *object;

    [self.dbReadConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        object = [transaction objectForKey:key inCollection:collection];
    }];

    return object;
}

- (id)keysObjectForKey:(NSString *)key inCollection:(NSString *)collection {
    __block NSString *object;

    [self.keysDBReadConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        object = [transaction objectForKey:key inCollection:collection];
    }];

    return object;
}

- (BOOL)boolForKey:(NSString *)key inCollection:(NSString *)collection {
    NSNumber *boolNum = [self objectForKey:key inCollection:collection];

    return [boolNum boolValue];
}

- (nullable ECKeyPair *)keyPairForKey:(NSString *)key inCollection:(NSString *)collection
{
    ECKeyPair *keyPair = [self keysObjectForKey:key inCollection:collection];

    return keyPair;
}

- (nullable PreKeyRecord *)preKeyRecordForKey:(NSString *)key inCollection:(NSString *)collection
{
    PreKeyRecord *preKeyRecord = [self keysObjectForKey:key inCollection:collection];

    return preKeyRecord;
}

- (nullable SignedPreKeyRecord *)signedPreKeyRecordForKey:(NSString *)key inCollection:(NSString *)collection
{
    SignedPreKeyRecord *preKeyRecord = [self keysObjectForKey:key inCollection:collection];

    return preKeyRecord;
}

- (int)intForKey:(NSString *)key inCollection:(NSString *)collection {
    int integer = [[self keysObjectForKey:key inCollection:collection] intValue];

    return integer;
}

- (void)setInt:(int)integer forKey:(NSString *)key inCollection:(NSString *)collection {
    [self setKeysObject:[NSNumber numberWithInt:integer] forKey:key inCollection:collection];
}

- (int)incrementIntForKey:(NSString *)key inCollection:(NSString *)collection
{
    __block int value = 0;
    [self.keysDBReadWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        value = [[transaction objectForKey:key inCollection:collection] intValue];
        value++;
        [transaction setObject:@(value) forKey:key inCollection:collection];
    }];
    return value;
}

- (nullable NSDate *)dateForKey:(NSString *)key inCollection:(NSString *)collection
{
    NSNumber *value = [self keysObjectForKey:key inCollection:collection];
    if (value) {
        return [NSDate dateWithTimeIntervalSince1970:value.doubleValue];
    } else {
        return nil;
    }
}

- (void)setDate:(NSDate *)value forKey:(NSString *)key inCollection:(NSString *)collection
{
    [self setKeysObject:@(value.timeIntervalSince1970) forKey:key inCollection:collection];
}

- (void)deleteThreadsAndMessages {
    [self.dbReadWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeAllObjectsInCollection:[TSThread collection]];
        [transaction removeAllObjectsInCollection:[SignalRecipient collection]];
        [transaction removeAllObjectsInCollection:[TSInteraction collection]];
        [transaction removeAllObjectsInCollection:[TSAttachment collection]];
    }];
    [TSAttachmentStream deleteAttachments];
}

- (void)deletePasswordFromKeychainForKey:(NSString *)key
{
    [SAMKeychain deletePasswordForService:key account:keychainDBPassAccount];
}

- (void)deleteDatabaseFile
{
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:[self dbPathWithName:databaseName] error:&error];
    if (error) {
        DDLogError(@"Failed to delete database: %@", error.description);
    }
}

- (void)backupDataBaseFile
{
    if (!self.accountName) {
        return;
    }

    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:[self dbPathWithName:databaseName] toPath:[self backupDatabasePath] error:&error];
    if (error) {
        DDLogError(@"Error moving DB file to backup path");
    }
}

- (void)resetSignalStorageWithBackup:(BOOL)withBackup
{
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:[self dbPathWithName:keysDBName] error:&error];
    if (error) {
        DDLogError(@"Failed to delete KEYS database: %@", error.description);
    }

    _keysDatabase = nil;
    _keysDBReadConnection = nil;
    _keysDBReadWriteConnection = nil;

    if (withBackup) {
        [self backupDataBaseFile];
    }

    self.database = nil;
    _dbReadConnection = nil;
    _dbReadWriteConnection = nil;

    [TSAttachmentStream deleteAttachments];

    [self deleteDatabaseFile];
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
