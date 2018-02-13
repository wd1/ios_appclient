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

class PasswordValidator {
    
    private init() {}
    static let shared = PasswordValidator()
    
    lazy var passwords: [String] = {
        guard let path = Bundle.main.path(forResource: "passwords-library", ofType: "txt") else {
            CrashlyticsLogger.log("Cannot get path to passwords file.")
            fatalError("Could not get path to passwords file")
        }
        
        do {
            let data = try String(contentsOfFile: path, encoding: .utf8)
            return data.components(separatedBy: .newlines)
        } catch {
            CrashlyticsLogger.log("Can not load passwords file")
            fatalError("Can't load data from file.")
        }
    }()
    
    lazy var maxCharacterCount: Int = {
        let passwordsByLength = passwords.sorted(by: { $1.count > $0.count })
        guard let longestPassword = passwordsByLength.last else {
            fatalError("could not get longest password")
        }
        
        return longestPassword.count
    }()
    
    func validateWord(for text: String) -> (match: String?, isSingleOccurrence: Bool) {
        guard !text.isEmpty else { return (nil, false) }
        
        let matchingPasswords = passwords.filter {
            $0.range(of: text, options: [.caseInsensitive, .anchored]) != nil
        }
        
        return (matchingPasswords.first, matchingPasswords.count == 1)
    }
}
