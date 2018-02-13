// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>
#import "PreKeyHandler.h"
#import "PrekeysRequest.h"
#import <SignalServiceKit/TSNetworkManager.h>
#import <SignalServiceKit/TSPreKeyManager.h>
#import "Toshi-Swift.h"

NSUInteger const PREKEY_MINIMUM_COUNT = 20;

@implementation PreKeyHandler

+ (void)tryRetrievingPrekeys
{
    NSURL *url = [NSURL URLWithString:textSecureKeysAPI];

    TSNetworkManager *networkManager = [TSNetworkManager sharedManager];
    __weak typeof(self) weakSelf = self;
    [networkManager makeRequest:[[PrekeysRequest alloc] initWithURL:url] success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

        typeof(self)strongSelf = weakSelf;

        NSDictionary *responseDict = (NSDictionary *)responseObject;
        NSInteger prekeysCount = [responseDict[@"count"] integerValue];
        if (prekeysCount < PREKEY_MINIMUM_COUNT) {
            [strongSelf refreshPrekeys];
        }
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

        [CrashlyticsLogger log:@"Failed retrieve prekeys - triggering Chat register" attributes:nil];

        if (error.code == 401) {
            [ChatAPIClient.shared registerUserWithCompletion:^(BOOL success) {
                if (success) {
                    [CrashlyticsLogger log:@"Successfully registered user with chat service after forced trigger" attributes:nil];
                } else {
                    [CrashlyticsLogger log:@"Failed to register user with chat service after forced trigger" attributes:nil];
                }
            }];
        }
    }];
}

+ (void)refreshPrekeys
{
    [TSPreKeyManager registerPreKeysWithMode:RefreshPreKeysMode_SignedAndOneTime
                                     success:^{
                                         [CrashlyticsLogger log:@"Successfully refreshed prekeys" attributes:nil];
                                     } failure:^(NSError *error) {
                                         [CrashlyticsLogger log:@"Failed registering prekeys - triggering Chat register" attributes:nil];

                                         if (error.code == 401) {
                                             [ChatAPIClient.shared registerUserWithCompletion:^(BOOL success) {
                                                 if (success) {
                                                     [CrashlyticsLogger log:@"Successfully registered user with chat service after forced trigger" attributes:nil];
                                                 } else {
                                                     [CrashlyticsLogger log:@"Failed to register user with chat service after forced trigger" attributes:nil];
                                                 }
                                             }];
                                         }
                                     }];
}

@end
