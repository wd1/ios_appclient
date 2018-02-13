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

typealias KeyTitle = String

extension KeyTitle {
    static var error = "error"
    static var occurred = "occurred"
    static var resultString = "result string"
    
    fileprivate static var userId = "user_id"
    fileprivate static var errorAttributres = "attributes"
    fileprivate static var developerDescription = "dev_description"
}

final class CrashlyticsClient {

    static func start(with apiKey: String) {
        Crashlytics.start(withAPIKey: apiKey)
        Fabric.with([Crashlytics.self])
    }

    static func setupForUser(with toshiID: String) {
        Crashlytics.sharedInstance().setUserIdentifier(toshiID)
    }
}

final class CrashlyticsLogger {
    
    private static func attributesWithUserID(from attributes: [KeyTitle: Any]?) -> [String: Any] {
        var resultAttributes: [String: Any] = [KeyTitle.userId: Cereal.shared.address]
        attributes?.forEach { key, value in resultAttributes[key] = value }
        
        return resultAttributes
    }
    
    /// Logs the given string to Crashlytics + Answers with the given attributes
    /// Useful for diagnosing problems and/or creating a breadcrumb trail of what the user was looking at.
    ///
    /// - Parameters:
    ///   - string: The string to log.
    ///   - attributes: (optional) any additional attributes to log with the string
    static func log(_ string: String, attributes: [KeyTitle: Any]? = nil) {
        CLSLogv("%@", getVaList([string]))
        let attributesToSend = attributesWithUserID(from: attributes)

        Answers.logCustomEvent(withName: string, customAttributes: attributesToSend)
    }
    
    /// Creates a non-fatal error, which shows up in Crashlytics similar to a crash but is filtered differently..
    ///
    /// - Parameters:
    ///   - description: The description of what happened to be logged in Crashlytics.
    ///   - error: (optional) Any associated NSError where you want to log domain, code, and LocalizedDescription.
    ///   - attributes: (optional) any additional attributes to log
    static func nonFatal(_ description: String, error: NSError? = nil, attributes: [KeyTitle: Any]? = nil) {
        let attributes = attributesWithUserID(from: attributes)
        
        let error = NSError(domain: error?.domain ?? "com.toshi.customnonfatal",
                            code: error?.code ?? 0,
                            userInfo: [
                                KeyTitle.errorAttributres: attributes,
                                NSLocalizedDescriptionKey: error?.localizedDescription ?? "(none)",
                                KeyTitle.developerDescription: description
                            ])
        
        Crashlytics.sharedInstance().recordError(error)
    }
}
