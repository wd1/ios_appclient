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
import PromiseKit

/// Not sure what this does yet, or if we actually need it.
class AccountManager: NSObject {
    let TAG = "[AccountManager]"
    let textSecureAccountManager: TSAccountManager

    required init(textSecureAccountManager: TSAccountManager) {
        self.textSecureAccountManager = textSecureAccountManager
    }

    @objc func register(verificationCode: String) -> AnyPromise {
        return AnyPromise(register(verificationCode: verificationCode))
    }

    func register(verificationCode: String) -> Promise<Void> {
        return firstly {
            Promise { fulfill, reject in

                if verificationCode.characters.isEmpty {
                    let error = OWSErrorWithCodeDescription(.userError, NSLocalizedString("REGISTRATION_ERROR_BLANK_VERIFICATION_CODE", comment: "alert body during registration"))
                    reject(error)
                }

                fulfill()
            }
        }.then {
            DLog("\(self.TAG) verification code looks well formed.")

            return self.registerForTextSecure(verificationCode: verificationCode)
        }.then {
            DLog("\(self.TAG) successfully registered for TextSecure")
        }
    }

    func updatePushTokens(pushToken: String) -> Promise<Void> {
        return firstly {
            self.updateTextSecurePushTokens(pushToken: pushToken)
        }.then {
            DLog("\(self.TAG) Successfully updated text secure push tokens.")
        }
    }

    private func updateTextSecurePushTokens(pushToken: String) -> Promise<Void> {
        return Promise { fulfill, reject in
            self.textSecureAccountManager.registerForPushNotifications(pushToken: pushToken, success: fulfill, failure: reject)
        }
    }

    private func registerForTextSecure(verificationCode: String) -> Promise<Void> {
        return Promise { fulfill, reject in
            self.textSecureAccountManager.verifyAccount(withCode: verificationCode,
                                                        success: fulfill,
                                                        failure: reject)
        }
    }
}
