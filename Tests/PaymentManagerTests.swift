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
import Foundation
import Teapot

class PaymentManagerTests: XCTestCase {

    func testPaymentInformation() {

        let mockTeapot = MockTeapot(bundle: Bundle(for: PaymentManagerTests.self), mockFilename: "transactionSkeleton")
        mockTeapot.overrideEndPoint(Cereal.shared.paymentAddress, withFilename: "getHighBalance")

        let parameters: [String: Any] = [
            "from": "0x011c6dd9565b8b83e6a9ee3f06e89ece3251ef2f",
            "to": "0x011c6dd9565b8b83e6a9ee3f06e89ece3251ef2f",
            "value": "0x330a41d05c8a780a"
        ]

        let paymentManager = PaymentManager(parameters: parameters, mockTeapot: mockTeapot, exchangeRate: 10)

        let expectation = XCTestExpectation(description: "Get payment Info")

        paymentManager.fetchPaymentInfo { paymentInfo in
            XCTAssertEqual(paymentInfo.totalEthereumString, "3.6787 ETH")
            XCTAssertEqual(paymentInfo.totalFiatString, "$36.79 USD")
            XCTAssertEqual(paymentInfo.estimatedFeesString, "$0.01 USD")
            XCTAssertEqual(paymentInfo.fiatString, "$36.78 USD")
            XCTAssertEqual(paymentInfo.balanceString, "$110.68 USD")
            XCTAssertTrue(paymentInfo.sufficientBalance)
            
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testPaymentInformationInsufficientBalance() {

        let mockTeapot = MockTeapot(bundle: Bundle(for: PaymentManagerTests.self), mockFilename: "transactionSkeleton")
        mockTeapot.overrideEndPoint(Cereal.shared.paymentAddress, withFilename: "getLowBalance")

        let parameters: [String: Any] = [
            "from": "0x011c6dd9565b8b83e6a9ee3f06e89ece3251ef2f",
            "to": "0x011c6dd9565b8b83e6a9ee3f06e89ece3251ef2f",
            "value": "0x330a41d05c8a780a"
        ]

        let paymentManager = PaymentManager(parameters: parameters, mockTeapot: mockTeapot, exchangeRate: 10)

        let expectation = XCTestExpectation(description: "Get payment Info")

        paymentManager.fetchPaymentInfo { paymentInfo in
            XCTAssertEqual(paymentInfo.totalEthereumString, "3.6787 ETH")
            XCTAssertEqual(paymentInfo.totalFiatString, "$36.79 USD")
            XCTAssertEqual(paymentInfo.estimatedFeesString, "$0.01 USD")
            XCTAssertEqual(paymentInfo.fiatString, "$36.78 USD")
            XCTAssertEqual(paymentInfo.balanceString, "$36.78 USD")
            XCTAssertFalse(paymentInfo.sufficientBalance)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testPaymentInformationSufficientBalance() {

        let mockTeapot = MockTeapot(bundle: Bundle(for: PaymentManagerTests.self), mockFilename: "transactionSkeleton")
        mockTeapot.overrideEndPoint(Cereal.shared.paymentAddress, withFilename: "getExactBalance")

        let parameters: [String: Any] = [
            "from": "0x011c6dd9565b8b83e6a9ee3f06e89ece3251ef2f",
            "to": "0x011c6dd9565b8b83e6a9ee3f06e89ece3251ef2f",
            "value": "0x330a41d05c8a780a"
        ]

        let paymentManager = PaymentManager(parameters: parameters, mockTeapot: mockTeapot, exchangeRate: 10)

        let expectation = XCTestExpectation(description: "Get payment Info")

        paymentManager.fetchPaymentInfo { paymentInfo in
            XCTAssertEqual(paymentInfo.totalEthereumString, "3.6787 ETH")
            XCTAssertEqual(paymentInfo.totalFiatString, "$36.79 USD")
            XCTAssertEqual(paymentInfo.estimatedFeesString, "$0.01 USD")
            XCTAssertEqual(paymentInfo.fiatString, "$36.78 USD")
            XCTAssertEqual(paymentInfo.balanceString, "$36.79 USD")
            XCTAssertTrue(paymentInfo.sufficientBalance)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
}
