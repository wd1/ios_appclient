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

/// Keys for the values being stored in NSUserDefaults.
/// New keys should be added with the `Restoration::` prefix.
/// Do not update old keys without providing some sort of migration path.
enum UserDefaultsKey: String, StringCaseListable {
    case
    databasePasswordAccessible = "DBPWD",
    enableDebugLog = "Debugging Log Enabled Key",
    lastRunSignalVersion = "SignalUpdateVersionKey",
    launchedBefore = "LaunchedBefore",
    moneyAlertShown = "DidShowMoneyAlert",
    requiresSignIn = "RequiresSignIn",
    selectedApp = "Restoration::SelectedApp",
    selectedContact = "Restoration::SelectedContact",
    selectedThreadAddress = "Restoration::SelectedThread",
    tabBarSelectedIndex = "TabBarSelectedIndex"
}

/// A wrapper for NSUserDefaults to facilitate type-safe fetching
class UserDefaultsWrapper: NSObject {
    
    /// The defaults to use. Exposed so it can be mocked if needed.
    static var defaults: UserDefaults {
        return UserDefaults.standard
    }
    
    /// Type-safe getter for values.
    ///
    /// - Parameter key: The key to use to query user defaults
    /// - Returns: The typed value, or nil if either the value was not present or was not of the correct type
    private static func value<T>(for key: UserDefaultsKey) -> T? {
        guard let typedValue = defaults.object(forKey: key.rawValue) as? T else {
            return nil
        }
        
        return typedValue
    }
    
    /// Generic setter for values
    ///
    /// - Parameters:
    ///   - value: The value to set, or nil. Passing in nil will cause the value to be removed from defaults.
    ///   - key: The key to set or remove the value for.
    private static func setValue<T>(_ value: T?, for key: UserDefaultsKey) {
        guard let value = value else {
            removeValue(for: key)
            return
        }
        
        defaults.set(value, forKey: key.rawValue)
    }
    
    /// Removes the value for the given key from defaults.
    ///
    /// - Parameter key: The key whose value you wish to remove.
    private static func removeValue(for key: UserDefaultsKey) {
        defaults.removeObject(forKey: key.rawValue)
    }
    
    private static func bool(for key: UserDefaultsKey) -> Bool {
        return defaults.bool(forKey: key.rawValue)
    }
    
    private static func string(for key: UserDefaultsKey) -> String? {
        return defaults.string(forKey: key.rawValue)
    }
    
    private static func int(for key: UserDefaultsKey) -> Int {
        return defaults.integer(forKey: key.rawValue)
    }
    
    private static func data(for key: UserDefaultsKey) -> Data? {
        return defaults.data(forKey: key.rawValue)
    }
    
    // MARK: - Variables for easier, type safe, and objc friendly access
    
    @objc static var isDebugLoggingEnabled: Bool {
        get {
            return bool(for: .enableDebugLog)
        }
        set {
            setValue(newValue, for: .enableDebugLog)
        }
    }
    
    static var isDatabasePasswordAccessible: Bool {
        get {
            return bool(for: .databasePasswordAccessible)
        }
        set {
            setValue(newValue, for: .databasePasswordAccessible)
        }
    }
    
    @objc static var lastRunSignalVersion: String? {
        get {
            return string(for: .lastRunSignalVersion)
        }
        set {
            setValue(newValue, for: .lastRunSignalVersion)
        }
    }
    
    @objc static var launchedBefore: Bool {
        get {
            return bool(for: .launchedBefore)
        }
        set {
            setValue(newValue, for: .launchedBefore)
        }
    }
    
    @objc static var moneyAlertShown: Bool {
        get {
            return bool(for: .moneyAlertShown)
        }
        set {
            setValue(newValue, for: .moneyAlertShown)
        }
    }
    
    @objc static var requiresSignIn: Bool {
        get {
            return bool(for: .requiresSignIn)
        }
        set {
            setValue(newValue, for: .requiresSignIn)
        }
    }
    
    static var selectedApp: Data? {
        get {
            return data(for: .selectedApp)
        }
        set {
            setValue(newValue, for: .selectedApp)
        }
    }
    
    static var selectedContact: String? {
        get {
            return string(for: .selectedContact)
        }
        set {
            setValue(newValue, for: .selectedContact)
        }
    }
    
    static var selectedThreadAddress: String? {
        get {
            return string(for: .selectedThreadAddress)
        }
        set {
            setValue(newValue, for: .selectedThreadAddress)
        }
    }
    
    static var tabBarSelectedIndex: Int {
        get {
            return int(for: .tabBarSelectedIndex)
        }
        set {
            setValue(newValue, for: .tabBarSelectedIndex)
        }
    }
    
    // MARK: - Removal of defaults for testing and sign out
    
    /// Clears the values for all keys directly stored by this wrapper.
    /// Mostly for testing purposes.
    static func clearDirectlyStoredDefaults() {
        UserDefaultsKey.allCases.forEach { removeValue(for: $0) }
    }
    
    /// Nukes the defaults for anything related to the application by nuking the whole domain, which ensures anything stored by libraries also gets zapped.
    /// Should be called when the user is signed out.
    @objc static func clearAllDefaultsForThisApplication() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            assertionFailure("No bundle identifier?!")
            return
        }
        
        defaults.removePersistentDomain(forName: bundleIdentifier)
    }
}
