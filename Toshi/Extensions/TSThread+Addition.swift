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

extension TSThread {

    /// Needs to be called on main thread as it involves UIAppDelegate
    func recipient() -> TokenUser? {
        guard let recipientAddress = contactIdentifier() else { return nil }

        var recipient: TokenUser?

        let retrievedData = contactData(for: recipientAddress)

        if let userData = retrievedData,
           let deserialised = (try? JSONSerialization.jsonObject(with: userData, options: [])),
           let json = deserialised as? [String: Any] {

            recipient = TokenUser(json: json, shouldSave: false)
        } else {
            recipient = SessionManager.shared.contactsManager.tokenContacts.first(where: { $0.address == recipientAddress })
        }

        return recipient
    }

    func avatar() -> UIImage {
        if let groupThread = self as? TSGroupThread {
            return groupThread.groupModel.avatarOrPlaceholder
        } else {
            return image() ?? #imageLiteral(resourceName: "avatar-placeholder")
        }
    }
    
    func updateGroupMembers() {
        if let groupThread = self as? TSGroupThread {

            let contactsIDs = SessionManager.shared.contactsManager.tokenContacts.map { $0.address }

            let recipientsIdsSet = Set(groupThread.recipientIdentifiers)
            let nonContactsUsersIds = recipientsIdsSet.subtracting(Set(contactsIDs))

            IDAPIClient.shared.updateContacts(with: Array(nonContactsUsersIds))

            for recipientId in groupThread.recipientIdentifiers {
                TSThread.saveRecipient(with: recipientId)
            }
        }
    }

    private func contactData(for address: String) -> Data? {
        return (Yap.sharedInstance.retrieveObject(for: address, in: TokenUser.storedContactKey) as? Data)
    }

    static func saveRecipient(with identifier: String) {
        TSStorageManager.shared().dbReadWriteConnection?.readWrite { transaction in

            var recipient = SignalRecipient(textSecureIdentifier: identifier, with: transaction)

            if recipient == nil {
                recipient = SignalRecipient(textSecureIdentifier: identifier, relay: nil)
            }

            recipient?.save(with: transaction)
        }
    }
}
