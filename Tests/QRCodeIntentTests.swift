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

import XCTest
import UIKit
@testable import Toshi

class QRCodeIntentTests: XCTestCase {
    struct UnexpectedNilError: Error {}

    func testAddressPaymentRequest() throws {
        guard let intent = QRCodeIntent(result: "iban:XE420ENF06QHAD2B0729XZJ1OU26UVM0TSN?amount=0.025&memo=thanks") else { throw UnexpectedNilError() }

        if case .paymentRequest(let weiValue, let address, let username, let memo) = intent {
            XCTAssertEqual(weiValue, "0x58d15e17628000")
            XCTAssertEqual(address, "0x037be053f866be6ee6dda11f258bd871b701a8d7")
            XCTAssertNil(username)
            XCTAssertEqual(memo, "thanks")
        } else {
            XCTFail("Could not create payment request from intent")
        }
    }

    func testAppLinkPaymentRequest() throws {
        guard let intent = QRCodeIntent(result: "https://app.toshi.org/pay/@mark?value=25000000000000000") else { throw UnexpectedNilError() }

        if case .paymentRequest(let weiValue, let address, let username, let memo) = intent {
            XCTAssertEqual(weiValue, "0x58d15e17628000")
            XCTAssertNil(address)
            XCTAssertEqual(username, "mark")
            XCTAssertNil(memo)
        } else {
            XCTFail("Could not create payment request from intent")
        }
    }

    func testAddressInput() throws {
        guard let intent = QRCodeIntent(result: "ethereum:0x037be053f866be6ee6dda11f258bd871b701a8d7") else { throw UnexpectedNilError() }

        if case .addressInput(let address) = intent {
            XCTAssertEqual(address, "0x037be053f866be6ee6dda11f258bd871b701a8d7")
        } else {
            XCTFail("Could not create address input from intent")
        }
    }

    func testWebSignin() throws {
        guard let intent = QRCodeIntent(result: "web-signin:a3e4c16114c50878") else { throw UnexpectedNilError() }

        if case .webSignIn(let loginToken) = intent {
            XCTAssertEqual(loginToken, "a3e4c16114c50878")
        } else {
            XCTFail("Could not web sign in from intent")
        }
    }

    func testAddContact() throws {
        guard let intent = QRCodeIntent(result: "https://app.toshi.org/add/@mark") else { throw UnexpectedNilError() }

        if case .addContact(let username) = intent {
            XCTAssertEqual(username, "mark")
        } else {
            XCTFail("Could not create contact from intent")
        }
    }
}
