//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SignalServiceKit/ProfileManagerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

extern const NSUInteger kOWSProfileManager_NameDataLength;

@interface ProfileManager : NSObject <ProfileManagerProtocol>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)sharedManager;

- (void)addThreadToProfileWhitelist:(TSThread *)thread;
- (BOOL)isThreadInProfileWhitelist:(TSThread *)thread;

@end

NS_ASSUME_NONNULL_END
