//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSIdentityManager.h"
#import "TSStorageManager+PreKeyStore.h"
#import "TSStorageManager+SignedPreKeyStore.h"
#import "TSStorageManager+keyFromIntLong.h"

#import <25519/Ed25519.h>
#import <AxolotlKit/AxolotlExceptions.h>
#import <AxolotlKit/NSData+keyVersionByte.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const TSStorageManagerSignedPreKeyStoreCollection = @"TSStorageManagerSignedPreKeyStoreCollection";
NSString *const TSStorageManagerSignedPreKeyMetadataCollection = @"TSStorageManagerSignedPreKeyMetadataCollection";
NSString *const TSStorageManagerKeyPrekeyUpdateFailureCount = @"prekeyUpdateFailureCount";
NSString *const TSStorageManagerKeyFirstPrekeyUpdateFailureDate = @"firstPrekeyUpdateFailureDate";
NSString *const TSStorageManagerKeyPrekeyCurrentSignedPrekeyId = @"currentSignedPrekeyId";

@implementation TSStorageManager (SignedPreKeyStore)

- (SignedPreKeyRecord *)generateRandomSignedRecord {
    ECKeyPair *keyPair = [Curve25519 generateKeyPair];

    // Signed prekey ids must be > 0.
    int preKeyId = 1 + arc4random_uniform(INT32_MAX - 1);
    ECKeyPair *_Nullable identityKeyPair = [[OWSIdentityManager sharedManager] identityKeyPair];
    return [[SignedPreKeyRecord alloc]
            initWithId:preKeyId
            keyPair:keyPair
            signature:[Ed25519 sign:keyPair.publicKey.prependKeyType withKeyPair:identityKeyPair]
            generatedAt:[NSDate date]];
}

- (SignedPreKeyRecord *)loadSignedPrekey:(int)signedPreKeyId {
    SignedPreKeyRecord *preKeyRecord = [self signedPreKeyRecordForKey:[self keyFromInt:signedPreKeyId]
                                                         inCollection:TSStorageManagerSignedPreKeyStoreCollection];

    if (!preKeyRecord) {
        @throw [NSException exceptionWithName:InvalidKeyIdException
                                       reason:@"No signed pre key found matching key id"
                                     userInfo:@{}];
    } else {
        return preKeyRecord;
    }
}

- (nullable SignedPreKeyRecord *)loadSignedPrekeyOrNil:(int)signedPreKeyId
{
    return [self signedPreKeyRecordForKey:[self keyFromInt:signedPreKeyId]
                             inCollection:TSStorageManagerSignedPreKeyStoreCollection];
}

- (NSArray *)loadSignedPreKeys {
    NSMutableArray *signedPreKeyRecords = [NSMutableArray array];

    YapDatabaseConnection *conn = [self newKeysDatabaseConnection];

    [conn readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateRowsInCollection:TSStorageManagerSignedPreKeyStoreCollection
                                    usingBlock:^(NSString *key, id object, id metadata, BOOL *stop) {
                                        [signedPreKeyRecords addObject:object];
                                    }];
    }];

    return signedPreKeyRecords;
}

- (void)storeSignedPreKey:(int)signedPreKeyId signedPreKeyRecord:(SignedPreKeyRecord *)signedPreKeyRecord {
    [self setKeysObject:signedPreKeyRecord
                 forKey:[self keyFromInt:signedPreKeyId]
           inCollection:TSStorageManagerSignedPreKeyStoreCollection];
}

- (BOOL)containsSignedPreKey:(int)signedPreKeyId {
    PreKeyRecord *preKeyRecord = [self signedPreKeyRecordForKey:[self keyFromInt:signedPreKeyId]
                                                   inCollection:TSStorageManagerSignedPreKeyStoreCollection];
    return (preKeyRecord != nil);
}

- (void)removeSignedPreKey:(int)signedPrekeyId {
    [self removeKeysObjectForKey:[self keyFromInt:signedPrekeyId] inCollection:TSStorageManagerSignedPreKeyStoreCollection];
}

- (nullable NSNumber *)currentSignedPrekeyId
{
    return [TSStorageManager.sharedManager keysObjectForKey:TSStorageManagerKeyPrekeyCurrentSignedPrekeyId
                                               inCollection:TSStorageManagerSignedPreKeyMetadataCollection];
}

- (void)setCurrentSignedPrekeyId:(int)value
{
    [TSStorageManager.sharedManager setKeysObject:@(value)
                                           forKey:TSStorageManagerKeyPrekeyCurrentSignedPrekeyId
                                     inCollection:TSStorageManagerSignedPreKeyMetadataCollection];
}

#pragma mark - Prekey update failures

- (int)prekeyUpdateFailureCount;
{
    NSNumber *value = [TSStorageManager.sharedManager keysObjectForKey:TSStorageManagerKeyPrekeyUpdateFailureCount
                                                          inCollection:TSStorageManagerSignedPreKeyMetadataCollection];
    // Will default to zero.
    return [value intValue];
}

- (void)clearPrekeyUpdateFailureCount
{
    [TSStorageManager.sharedManager removeKeysObjectForKey:TSStorageManagerKeyPrekeyUpdateFailureCount
                                              inCollection:TSStorageManagerSignedPreKeyMetadataCollection];
}

- (int)incrementPrekeyUpdateFailureCount
{
    return [TSStorageManager.sharedManager incrementIntForKey:TSStorageManagerKeyPrekeyUpdateFailureCount
                                                 inCollection:TSStorageManagerSignedPreKeyMetadataCollection];
}

- (nullable NSDate *)firstPrekeyUpdateFailureDate
{
    return [TSStorageManager.sharedManager dateForKey:TSStorageManagerKeyFirstPrekeyUpdateFailureDate
                                         inCollection:TSStorageManagerSignedPreKeyMetadataCollection];
}

- (void)setFirstPrekeyUpdateFailureDate:(nonnull NSDate *)value
{
    [TSStorageManager.sharedManager setDate:value
                                     forKey:TSStorageManagerKeyFirstPrekeyUpdateFailureDate
                               inCollection:TSStorageManagerSignedPreKeyMetadataCollection];
}

- (void)clearFirstPrekeyUpdateFailureDate
{
    [TSStorageManager.sharedManager removeKeysObjectForKey:TSStorageManagerKeyFirstPrekeyUpdateFailureDate
                                              inCollection:TSStorageManagerSignedPreKeyMetadataCollection];
}

#pragma mark - Debugging

- (void)logSignedPreKeyReport
{
    NSString *tag = @"[TSStorageManager (SignedPreKeyStore)]";

    NSNumber *currentId = [self currentSignedPrekeyId];
    NSDate *firstPrekeyUpdateFailureDate = [self firstPrekeyUpdateFailureDate];
    NSUInteger prekeyUpdateFailureCount = [self prekeyUpdateFailureCount];

    [self.keysDBReadConnection readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        __block int i = 0;

        DDLogInfo(@"%@ SignedPreKeys Report:", tag);
        DDLogInfo(@"%@   currentId: %@", tag, currentId);
        DDLogInfo(@"%@   firstPrekeyUpdateFailureDate: %@", tag, firstPrekeyUpdateFailureDate);
        DDLogInfo(@"%@   prekeyUpdateFailureCount: %lu", tag, (unsigned long)prekeyUpdateFailureCount);

        NSUInteger count = [transaction numberOfKeysInCollection:TSStorageManagerSignedPreKeyStoreCollection];
        DDLogInfo(@"%@   All Keys (count: %lu):", tag, (unsigned long)count);

        [transaction
         enumerateKeysAndObjectsInCollection:TSStorageManagerSignedPreKeyStoreCollection
         usingBlock:^(
                      NSString *_Nonnull key, id _Nonnull signedPreKeyObject, BOOL *_Nonnull stop) {
             i++;
             if (![signedPreKeyObject isKindOfClass:[SignedPreKeyRecord class]]) {
                 OWSFail(@"%@ Was expecting SignedPreKeyRecord, but found: %@",
                         tag,
                         signedPreKeyObject);
                 return;
             }
             SignedPreKeyRecord *signedPreKeyRecord
             = (SignedPreKeyRecord *)signedPreKeyObject;
             DDLogInfo(@"%@     #%d <SignedPreKeyRecord: id: %d, generatedAt: %@, "
                       @"wasAcceptedByService:%@, signature: %@",
                       tag,
                       i,
                       signedPreKeyRecord.Id,
                       signedPreKeyRecord.generatedAt,
                       (signedPreKeyRecord.wasAcceptedByService ? @"YES" : @"NO"),
                       signedPreKeyRecord.signature);
         }];
    }];
}

@end

NS_ASSUME_NONNULL_END
