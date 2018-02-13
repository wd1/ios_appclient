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

@testable import Toshi
import XCTest

class PasswordValidatorTests: XCTestCase {
    
    func testLoadingWords() {
        XCTAssertEqual(PasswordValidator.shared.passwords.count, 2049)
    }
    
    func testValidatingKnownProblematicWords() {
        let you = "you"
        let youValidationResult = PasswordValidator.shared.validateWord(for: you)
        XCTAssertEqual(youValidationResult.match, you)
        
        // There are several items with a prefix of "you", so "you" should not be the only occurrence
        XCTAssertEqual(youValidationResult.isSingleOccurrence, false)
        
        let blank = ""
        let blankValidationResult = PasswordValidator.shared.validateWord(for: blank)
        XCTAssertNil(blankValidationResult.match)
    }
    
    func testGettingLongestPassword() {
        XCTAssertEqual(PasswordValidator.shared.maxCharacterCount, 8)
    }
}
