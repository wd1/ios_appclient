//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSYapDatabaseObject.h"
#import <Mantle/MTLJSONAdapter.h>

NS_ASSUME_NONNULL_BEGIN

extern uint32_t const OWSDevicePrimaryDeviceId;

@interface OWSDevice : TSYapDatabaseObject <MTLJSONSerializing>

@property (nonatomic, readonly) NSInteger deviceId;
@property (nullable, readonly) NSString *name;
@property (readonly) NSDate *createdAt;
@property (readonly) NSDate *lastSeenAt;

+ (instancetype)deviceFromJSONDictionary:(NSDictionary *)deviceAttributes error:(NSError **)error;

/**
 * Set local database of devices to `devices`.
 *
 * This will create missing devices, update existing devices, and delete stale devices.
 * @param devices Removes any existing devices, replacing them with `devices`
 */
+ (void)replaceAll:(NSArray<OWSDevice *> *)devices;

/**
 * The id of the device currently running this application
 */
+ (uint32_t)currentDeviceId;

/**
 *
 * @param transaction yapTransaction
 * @return
 *   If the user has any linked devices (apart from the device this app is running on).
 */
+ (BOOL)hasSecondaryDevicesWithTransaction:(YapDatabaseReadTransaction *)transaction;

- (NSString *)displayName;
- (BOOL)isPrimaryDevice;

/**
 * Assign attributes to this device from another.
 *
 * @param other
 *  OWSDevice whose attributes to copy to this device
 * @return
 *  YES if any values on self changed, else NO
 */
- (BOOL)updateAttributesWithDevice:(OWSDevice *)other;

@end

NS_ASSUME_NONNULL_END
