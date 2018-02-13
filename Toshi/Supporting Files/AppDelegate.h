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

#import <UIKit/UIKit.h>
#import <SignalServiceKit/TSNetworkManager.h>
#import <SignalServiceKit/OWSMessageSender.h>
#import <SignalServiceKit/ContactsUpdater.h>
#import "ContactsManager.h"

#import <PushKit/PushKit.h>
#import <UserNotifications/UserNotifications.h>


@interface AppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>

@property (nullable, strong, nonatomic) UIWindow *window;

@property (nonnull, nonatomic) TSNetworkManager *networkManager;
@property (nonnull, nonatomic) ContactsManager *contactsManager;
@property (nonnull, nonatomic) ContactsUpdater *contactsUpdater;
@property (nonnull, nonatomic) OWSMessageSender *messageSender;

@property (nonnull, nonatomic, copy, readonly) NSString *token;

- (void)createNewUser;
- (void)signInUser;

- (void)setupSignalService;

+ (nonnull NSString *)documentsPath;

- (void)signOutUser;

@end

