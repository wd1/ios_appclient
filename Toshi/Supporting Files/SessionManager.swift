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

enum SignInResult {
    case succeeded
    case passphraseVerificationFailure
    case signUpWithPassphrase
}

final class SessionManager {

    static let shared = SessionManager()

    private(set) var networkManager: TSNetworkManager
    private(set) var contactsManager: ContactsManager
    private(set) var contactsUpdater: ContactsUpdater
    private(set) var messageSender: MessageSender

    init() {
        self.networkManager = TSNetworkManager.shared()
        self.contactsManager = ContactsManager()
        self.contactsUpdater = ContactsUpdater.shared()

        messageSender = MessageSender(networkManager: networkManager, storageManager: TSStorageManager.shared(), contactsManager: contactsManager, contactsUpdater: contactsUpdater)
    }

    func setupSecureEnvironment() {
        TSAccountManager.sharedInstance().storeLocalNumber(Cereal.shared.address)

        let sharedEnv = TextSecureKitEnv(callMessageHandler: EmptyCallHandler(), contactsManager: contactsManager, messageSender: messageSender, notificationsManager: SignalNotificationManager(), profileManager: ProfileManager.shared())
        TextSecureKitEnv.setShared(sharedEnv)
    }

    func signOutUser() {

        TSAccountManager.unregisterTextSecure(success: {

            NotificationCenter.default.post(name: .UserDidSignOut, object: nil)
            AvatarManager.shared.cleanCache()

            UserDefaultsWrapper.clearAllDefaultsForThisApplication()

            EthereumAPIClient.shared.deregisterFromMainNetworkPushNotifications()

            let shouldBackupChatDB = TokenUser.current?.verified ?? false
            TSStorageManager.shared().resetSignalStorage(withBackup: shouldBackupChatDB)
            Yap.sharedInstance.wipeStorage()

            UserDefaultsWrapper.requiresSignIn = true

            UIApplication.shared.applicationIconBadgeNumber = 0

            SessionManager.shared.contactsManager.refreshContacts()

            exit(0)

        }, failure: { _ in

            let alertController = UIAlertController(title: Localized("sign-out-failure-title"),
                                                    message: Localized("sign-out-failure-message"),
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: Localized("alert-ok-action-title"),
                                                    style: .default,
                                                    handler: nil))
            Navigator.presentModally(alertController)
        })
    }

    func signInUser(_ passphrase: [String], completion: @escaping ((SignInResult) -> Void)) {
        guard Cereal.areWordsValid(passphrase), let validCereal = Cereal(words: passphrase) else {
            completion(.passphraseVerificationFailure)
            return
        }
        
        let idClient = IDAPIClient.shared
        idClient.retrieveUser(username: validCereal.address) { user in

            guard let user = user else {
                completion(.signUpWithPassphrase)
                return
            }

            Cereal.shared = validCereal
            UserDefaultsWrapper.requiresSignIn = false

            TokenUser.createCurrentUser(with: user.dict)
            idClient.migrateCurrentUserIfNeeded()

            TokenUser.current?.updateVerificationState(true)

            ChatAPIClient.shared.registerUser()

            (UIApplication.shared.delegate as? AppDelegate)?.didSignInUser()

            completion(.succeeded)
        }
    }

    func createNewUser() {
        IDAPIClient.shared.registerUserIfNeeded { [weak self] status in
            guard status != UserRegisterStatus.failed else { return }

            UserDefaultsWrapper.requiresSignIn = false

            (UIApplication.shared.delegate as? AppDelegate)?.setupDB()

            self?.contactsManager.refreshContacts()

            ChatAPIClient.shared.registerUser(completion: { _ in
                guard status == UserRegisterStatus.registered else { return }
                ChatInteractor.triggerBotGreeting()
            })
        }
    }
}
