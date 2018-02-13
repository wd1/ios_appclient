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

#import <Contacts/Contacts.h>
#import <Foundation/Foundation.h>
#import <SignalServiceKit/ContactsManagerProtocol.h>
#import <SignalServiceKit/PhoneNumber.h>
#import "CollapsingFutures.h"

/**
 Get Signal or Token contacts. 
 */

@class TokenUser;

@interface ContactsManager : NSObject <ContactsManagerProtocol>

@property (nonatomic, copy, readonly, nonnull) NSArray<TokenUser *> *tokenContacts;

+ (BOOL)name:(nonnull NSString *)nameString matchesQuery:(nonnull NSString *)queryString;

- (nonnull NSString *)displayNameForPhoneIdentifier:(nullable NSString *)phoneNumber;

- (nonnull NSArray<SignalAccount *> *)signalAccounts;
- (nullable TokenUser *)tokenContactForAddress:(nullable NSString *)address;

- (nullable UIImage *)imageForPhoneIdentifier:(nullable NSString *)phoneNumber;

- (void)refreshContacts;
- (void)refreshContact:(nonnull TokenUser *)contact;

@end
