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
import SweetSwift
import KeychainSwift

extension NSNotification.Name {
    static let currentUserUpdated = NSNotification.Name(rawValue: "currentUserUpdated")
    static let userCreated = NSNotification.Name(rawValue: "userCreated")
    static let userLoggedIn = NSNotification.Name(rawValue: "userLoggedIn")
    static let localCurrencyUpdated = NSNotification.Name(rawValue: "localCurrencyUpdated")
}

typealias UserInfo = (address: String, paymentAddress: String?, avatarPath: String?, name: String?, username: String?, isLocal: Bool)

final class TokenUsersCacheData: NSObject, NSCoding {

    var objects: [TokenUser]?

    override init() {
        super.init()
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(objects, forKey: "objects")
    }

    init?(coder aDecoder: NSCoder) {
        if let apps = aDecoder.decodeObject(forKey: "objects") as? [TokenUser] {
            self.objects = apps
        }

        super.init()
    }
}

class TokenUser: NSObject, NSCoding {

    struct Constants {
        static let name = "name"
        static let username = "username"
        static let address = "token_id"
        static let paymentAddress = "payment_address"
        static let location = "location"
        static let about = "about"
        static let avatar = "avatar"
        static let isApp = "is_app"
        static let verified = "verified"
        static let isPublic = "public"
        static let reputationScore = "reputation_score"
        static let averageRating = "average_rating"
        static let localCurrency = "local_currency"
    }

    @objc static let viewExtensionName = "TokenContactsDatabaseViewExtensionName"
    static let favoritesCollectionKey: String = "TokenContacts"

    static let legacyStoredUserKey = "StoredUser"

    static let currentLocalUserAddressKey = "currentLocalUserAddress"
    @objc static let storedContactKey = "storedContactKey"
    static let localUserSettingsKey = "localUserSettings"

    var category = ""

    var balance = NSDecimalNumber.zero

    @objc private(set) var name = ""

    var displayUsername: String {
        return "@\(username)"
    }
    
    /// Returns the display username if the user's name is empty. Useful for places where we're trying to mostly display names, but some users haven't set them.
    var nameOrDisplayName: String {
        guard !name.isEmpty else {
            
            return displayUsername
        }
        
        return name
    }

    @objc private(set) var username = ""
    private(set) var about = ""
    private(set) var location = ""
    @objc private(set) var avatarPath = ""

    private(set) var isPublic = false

    @objc private(set) var address = ""
    private(set) var paymentAddress = ""
    private(set) var isApp: Bool = false
    private(set) var reputationScore: Float?
    private(set) var averageRating: Float?

    var localCurrency: String {
        return userSettings[Constants.localCurrency] as? String ?? TokenUser.defaultCurrency
    }

    @objc var verified: Bool {
        return userSettings[Constants.verified] as? Bool ?? false
    }

    private var userSettings: [String: Any] = [:]
    private(set) var cachedCurrencyLocale: Locale?

    private static var _current: TokenUser?
    @objc private(set) static var current: TokenUser? {
        get {
            if _current == nil {
                _current = retrieveCurrentUserFromStore()
            }

            return _current
        }
        set {
            guard _current != newValue else { return }

            newValue?.update()

            if let user = newValue {
                user.save()
            }

            _current = newValue
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .currentUserUpdated, object: nil)
            }
        }
    }
    
    static var defaultCurrency: String {
        return Locale.current.currencyCode ?? "USD"
    }

    var isBlocked: Bool {
        let blockingManager = OWSBlockingManager.shared()

        return blockingManager.blockedPhoneNumbers().contains(address)
    }

    var isCurrentUser: Bool {
        return address == Cereal.shared.address
    }

    var json: Data {
        do {
            return try JSONSerialization.data(withJSONObject: dict, options: [])
        } catch {
            fatalError("Unable to create JSON from TokenUser dictionary")
        }
    }

    var dict: [String: Any] {
        return [
            Constants.address: self.address,
            Constants.paymentAddress: self.paymentAddress,
            Constants.username: self.username,
            Constants.about: self.about,
            Constants.location: self.location,
            Constants.name: self.name,
            Constants.avatar: self.avatarPath,
            Constants.isApp: self.isApp,
            Constants.isPublic: self.isPublic,
            Constants.reputationScore: self.reputationScore as Any,
            Constants.averageRating: self.averageRating as Any
        ]
    }

    var userInfo: UserInfo {
        return UserInfo(address: address, paymentAddress: paymentAddress, avatarPath: avatarPath, name: nameOrDisplayName, username: displayUsername, isLocal: true)
    }

    override var description: String {
        return "<User: address: \(address), payment address: \(paymentAddress), name: \(name), username: \(username), avatarPath: \(avatarPath)>"
    }

    static func name(from username: String) -> String {
        guard username.hasPrefix("@") else {
            // Does not need to be cleaned up
            return username
        }

        let index = username.index(username.startIndex, offsetBy: 1)
        return String(username[index...])
    }

    static func user(with data: Data, shouldUpdate: Bool = true) -> TokenUser? {
        guard let deserialised = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
        guard let json = deserialised as? [String: Any] else { return nil }

        return TokenUser(json: json, shouldSave: shouldUpdate)
    }

    @objc init(json: [String: Any], shouldSave: Bool = true) {
        super.init()

        update(json: json, updateAvatar: true, shouldSave: shouldSave)

        setupNotifications()
    }

    required convenience init?(coder aDecoder: NSCoder) {
        guard let jsonData = aDecoder.decodeObject(forKey: "jsonData") as? Data else { return nil }
        guard let deserialised = try? JSONSerialization.jsonObject(with: jsonData, options: []), let json = deserialised as? [String: Any] else { return nil }

        self.init(json: json)
    }

    @objc(encodeWithCoder:)
    func encode(with aCoder: NSCoder) {
        aCoder.encode(json, forKey: "jsonData")
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? TokenUser else { return false }
        
        return self == other
    }
    
    static func == (_ lhs: TokenUser, _ rhs: TokenUser) -> Bool {
        guard
            lhs.address == rhs.address,
            lhs.paymentAddress == rhs.paymentAddress else {
                return false
        }
        
        return true
    }
    
    public override var hashValue: Int {
        return address.hashValue
    }
    
    func updateVerificationState(_ verified: Bool) {
        self.userSettings[Constants.verified] = verified
        saveSettings()
    }

    func update(json: [String: Any], updateAvatar _: Bool = false, shouldSave: Bool = true) {
        isPublic = json[Constants.isPublic] as? Bool ?? isPublic
        address = json[Constants.address] as? String ?? address
        paymentAddress = (json[Constants.paymentAddress] as? String) ?? address
        username = json[Constants.username] as? String ?? username
        name = json[Constants.name] as? String ?? name
        location = json[Constants.location] as? String ?? location
        about = json[Constants.about] as? String ?? about
        avatarPath = json[Constants.avatar] as? String ?? avatarPath
        isApp = json[Constants.isApp] as? Bool ?? isApp
        reputationScore = json[Constants.reputationScore] as? Float ?? reputationScore
        averageRating = json[Constants.averageRating] as? Float ?? averageRating

        if shouldSave {
            save()
        }
    }

    func update(avatar _: UIImage, avatarPath: String) {
        self.avatarPath = avatarPath

        save()
    }

    func update(username: String? = nil, name: String? = nil, about: String? = nil, location: String? = nil) {
        self.username = username ?? self.username
        self.name = name ?? self.name
        self.about = about ?? self.about
        self.location = location ?? self.location

        save()
    }

    func updatePublicState(to isPublic: Bool) {
        self.isPublic = isPublic

        IDAPIClient.shared.updateUser(dict) { _, _ in }

        save()
    }

    func updateLocalCurrency(code: String? = nil, shouldSave: Bool = true) {
        if let localCurrency = code {
            userSettings[Constants.localCurrency] = localCurrency

            adjustToLocalCurrency()

            if shouldSave {
                saveSettings()
            }
        }
    }

    static func createCurrentUser(with json: [String: Any]) {
        let newUser = TokenUser(json: json, shouldSave: false)

        current = newUser

        Yap.sharedInstance.setupForNewUser(with: newUser.address)

        let newUserSettings: [String: Any] = [
            Constants.localCurrency: TokenUser.defaultCurrency,
            Constants.verified: 0
        ]

        newUser.userSettings = Yap.sharedInstance.retrieveObject(for: Cereal.shared.address, in: TokenUser.localUserSettingsKey) as? [String: Any] ?? newUserSettings
        current?.saveSettings()
        current?.adjustToLocalCurrency()

        NotificationCenter.default.post(name: .userCreated, object: nil)
    }

    @objc static func retrieveCurrentUser() {
        current = retrieveCurrentUserFromStore()

        NotificationCenter.default.post(name: .userCreated, object: nil)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateIfNeeded), name: IDAPIClient.didFetchContactInfoNotification, object: nil)
    }

    @objc private func updateIfNeeded(_ notification: Notification) {
        guard let tokenContact = notification.object as? TokenUser else { return }
        guard tokenContact.address == address else { return }

        if name == tokenContact.name && username == tokenContact.username && location == tokenContact.location && about == tokenContact.about {
            return
        }

        update(username: tokenContact.username, name: tokenContact.name, about: tokenContact.about, location: tokenContact.location)
    }

    private func save() {
        Yap.sharedInstance.insert(object: json, for: address, in: TokenUser.storedContactKey)
    }

    private func saveSettings() {
        Yap.sharedInstance.insert(object: userSettings, for: address, in: TokenUser.localUserSettingsKey)
    }

    private func adjustToLocalCurrency() {
        updateLocalCurrencyLocaleCache()

        ExchangeRateClient.updateRate({ _ in
            NotificationCenter.default.post(name: .localCurrencyUpdated, object: nil)
        })
    }

    private static func retrieveCurrentUserFromStore() -> TokenUser? {
        var user: TokenUser?

        // migrate old user storage
        if _current == nil, let userData = (Yap.sharedInstance.retrieveObject(for: TokenUser.legacyStoredUserKey) as? Data) {
            Yap.sharedInstance.insert(object: userData, for: Cereal.shared.address, in: TokenUser.storedContactKey)
            Yap.sharedInstance.removeObject(for: TokenUser.legacyStoredUserKey)
        }

        if _current == nil,
            let userData = (Yap.sharedInstance.retrieveObject(for: Cereal.shared.address, in: TokenUser.storedContactKey) as? Data),
            let deserialised = (try? JSONSerialization.jsonObject(with: userData, options: [])),
            var json = deserialised as? [String: Any] {

            var userSettings = Yap.sharedInstance.retrieveObject(for: Cereal.shared.address, in: TokenUser.localUserSettingsKey) as? [String: Any] ?? [:]

            // Because of payment address migration, we have to override the stored payment address.
            // Otherwise users will be sending payments to the wrong address.
            if json[Constants.paymentAddress] as? String != Cereal.shared.paymentAddress {
                json[Constants.paymentAddress] = Cereal.shared.paymentAddress
            }

            user = TokenUser(json: json, shouldSave: false)

            // migrations
            var shouldSaveMigration = false
            if userSettings[Constants.verified] == nil {
                if json[Constants.verified] != nil {
                    userSettings[Constants.verified] = json[Constants.verified]
                } else {
                    userSettings[Constants.verified] = 0
                }
                shouldSaveMigration = true
            }

            if userSettings[Constants.localCurrency] == nil {
                userSettings[Constants.localCurrency] = TokenUser.defaultCurrency
                shouldSaveMigration = true
            }

            user?.userSettings = userSettings
            if shouldSaveMigration {
                user?.saveSettings()
            }
            user?.updateLocalCurrencyLocaleCache()
        }

        return user
    }

    private func updateLocalCurrencyLocaleCache() {
        if Locale.current.currencyCode == self.localCurrency {
            cachedCurrencyLocale = Locale.current
        } else if let defaultLocaleForCurrency = Currency.defaultLocalesForCurrencies[self.localCurrency] {
            self.cachedCurrencyLocale = Locale(identifier: defaultLocaleForCurrency)
        } else {
            self.cachedCurrencyLocale = Locale.current
        }
    }
}

extension TokenUser: BrowseableItem {
    
    var nameForBrowseAndSearch: String {
        guard !name.isEmpty else {
            return (isApp ? category : username)
        }
        
        return name
    }
    
    var descriptionForSearch: String {
        return (isApp ? about : username)
    }
    
    var shouldShowRating: Bool {
        return true
    }
    
    var rating: Float? {
        return averageRating
    }
}
