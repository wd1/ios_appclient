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

class NSDecimalNumberAdditionsTests: XCTestCase {
   func testDecimalNumberFromHexadecimalString() {
        XCTAssertEqual(NSDecimalNumber(hexadecimalString: "0x150d52c424663ea"), 94809978241967082)
    }

    func testIsGreaterOrEqualThan() {
        let bigNumber: NSDecimalNumber = 10000
        let smallNumber: NSDecimalNumber = 1

        XCTAssertTrue(bigNumber.isGreaterOrEqualThan(value: smallNumber))
        XCTAssertTrue(bigNumber.isGreaterOrEqualThan(value: bigNumber))
        XCTAssertFalse(smallNumber.isGreaterOrEqualThan(value: bigNumber))
    }

    func testIsGreaterThan() {
        let bigNumber: NSDecimalNumber = 10000
        let smallNumber: NSDecimalNumber = 1

        XCTAssertTrue(bigNumber.isGreaterThan(value: smallNumber))
        XCTAssertFalse(bigNumber.isGreaterThan(value: bigNumber))
        XCTAssertFalse(smallNumber.isGreaterThan(value: bigNumber))
    }
}
