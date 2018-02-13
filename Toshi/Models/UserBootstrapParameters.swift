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
import SweetFoundation

/// Prepares user keys and data, signs and formats it properly as JSON to bootstrap a chat user.
class UserBootstrapParameter {

    // This change might require re-creating Signal users
    lazy var password: String = {
        return UUID().uuidString
    }()

    let identityKey: String

    let lastResortPreKey: PreKeyRecord

    let prekeys: [PreKeyRecord]

    let registrationId: UInt32

    let signalingKey: String

    let signedPrekey: SignedPreKeyRecord

    lazy var payload: [String: Any] = {
        var prekeys = [[String: Any]]()

        for prekey in self.prekeys {
            let prekeyParam: [String: Any] = [
                "keyId": prekey.id,
                "publicKey": ((prekey.keyPair.publicKey() as NSData).prependKeyType() as Data).base64EncodedString()
            ]
            prekeys.append(prekeyParam)
        }

        let lastResortKey: [String: Any] = [
            "keyId": Int(self.lastResortPreKey.id),
            "publicKey": ((self.lastResortPreKey.keyPair.publicKey() as NSData).prependKeyType() as Data).base64EncodedString()
        ]
        let signedPreKey: [String: Any] = [
            "keyId": Int(self.signedPrekey.id),
            "publicKey": ((self.signedPrekey.keyPair.publicKey() as NSData).prependKeyType() as Data).base64EncodedString(),
            "signature": self.signedPrekey.signature.base64EncodedString()
        ]

        let payload: [String: Any] = [
            "identityKey": self.identityKey,
            "lastResortKey": lastResortKey,
            "password": self.password,
            "preKeys": prekeys,
            "registrationId": Int(self.registrationId),
            "signalingKey": self.signalingKey,
            "signedPreKey": signedPreKey
        ]

        return payload
    }()

    // swiftlint:disable force_cast
    // Because this method relies heavily on obj-c classes, we need to force cast some values here.
    init() {
        let identityManager = OWSIdentityManager.shared()

        if identityManager.identityKeyPair() == nil {
            identityManager.generateNewIdentityKey()
        }

        guard let identityKeyPair = identityManager.identityKeyPair() else {
            CrashlyticsLogger.log("No identity key pair", attributes: [.occurred: "User bootstrap parameters init"])
            fatalError("No ID key pair for current user!")
        }

        let storageManager = TSStorageManager.shared()

        identityKey = ((identityKeyPair.publicKey() as NSData).prependKeyType() as Data).base64EncodedString()
        lastResortPreKey = storageManager.getOrGenerateLastResortKey()

        prekeys = storageManager.generatePreKeyRecords() as! [PreKeyRecord]

        registrationId = TSAccountManager.getOrGenerateRegistrationId()

        signalingKey = CryptoTools.generateSecureRandomData(52).base64EncodedString()

        let keyPair = Curve25519.generateKeyPair()
        let keyToSign = (keyPair!.publicKey()! as NSData).prependKeyType()! as Data
        let signature = Ed25519.sign(keyToSign, with: identityManager.identityKeyPair()) as Data

        signedPrekey = SignedPreKeyRecord(id: Int32(0), keyPair: keyPair, signature: signature, generatedAt: Date())!

        for prekey in prekeys {
            storageManager.storePreKey(prekey.id, preKeyRecord: prekey)
        }

        storageManager.storeSignedPreKey(signedPrekey.id, signedPreKeyRecord: signedPrekey)
    }
    // swiftlint:enable force_cast
}
