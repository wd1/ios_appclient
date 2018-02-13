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

import Foundation

final class PrekeyHandler {

    static let prekeysMinimumCount = 20

    static func tryRetrievingPrekeys() {

        guard let url = URL(string: textSecureKeysAPI) else { return }

        let networkManager = TSNetworkManager.shared()

        networkManager.makeRequest(PrekeysRequest(url: url), success: { _, responseObject in

            if let responseDictionary = responseObject as? [String: Any],
                let prekeysCount = responseDictionary["count"] as? Int {

                if prekeysCount < prekeysMinimumCount {
                    refreshPrekeys()
                }
            }

        }, failure: { _, error in

            CrashlyticsLogger.log("Failed retrieve prekeys - triggering Chat register")

            guard (error as NSError).code == 401 else { return }

            tryRegisteringUserWithChatService()
        })
    }

    private static func refreshPrekeys() {

        TSPreKeyManager.registerPreKeys(with: RefreshPreKeysMode.signedAndOneTime, success: {
            CrashlyticsLogger.log("Successfully refreshed prekeys")
        }, failure: { error in
            guard (error as NSError?)?.code == 401 else { return }

            tryRegisteringUserWithChatService()
        })
    }

    private static func tryRegisteringUserWithChatService() {
        ChatAPIClient.shared.registerUser(completion: { success in
            if success {
                CrashlyticsLogger.log("Successfully registered user with chat service after forced trigger")
            } else {
                CrashlyticsLogger.log("Failed to register user with chat service after forced trigger")
            }
        })
    }
}
