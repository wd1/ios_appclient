//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSReadTracking.h"
#import "TSInteraction.h"

NS_ASSUME_NONNULL_BEGIN

@class TSContactThread;

typedef enum {
    RPRecentCallTypeIncoming = 1,
    RPRecentCallTypeOutgoing,
    RPRecentCallTypeMissed,
    // These call types are used until the call connects.
    RPRecentCallTypeOutgoingIncomplete,
    RPRecentCallTypeIncomingIncomplete,
    RPRecentCallTypeMissedBecauseOfChangedIdentity,
    RPRecentCallTypeIncomingDeclined
} RPRecentCallType;

@interface TSCall : TSInteraction <OWSReadTracking>

@property (nonatomic, readonly) RPRecentCallType callType;

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                   withCallNumber:(NSString *)contactNumber
                         callType:(RPRecentCallType)callType
                         inThread:(TSContactThread *)thread NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

- (void)updateCallType:(RPRecentCallType)callType;

@end

NS_ASSUME_NONNULL_END
