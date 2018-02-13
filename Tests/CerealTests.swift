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
import XCTest
@testable import Toshi

class CerealSignEthereumTransactionWithWalletTests: XCTestCase {

    private var cereal: Cereal {
        guard let c = Cereal(words: ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "about"]) else {
            fatalError("failed to create cereal")
        }
        return c
    }

    func testWithUnsignedTransaction() {
        let transactionSkeleton = "0xe585746f6b6682832dc6c0832dc6c094dc0a63a5bdb165640661709569816bf08594dfd78080"
        let expectedSignedTransaction = "0xf86885746f6b6682832dc6c0832dc6c094dc0a63a5bdb165640661709569816bf08594dfd780801ca0f7afe4aa4d329056865ed31d1bf13765348495438bfdd66418de440bed3d626da012ae7c764b96bebcc9ef6b6c8f0dcc760b229f14c939adac42b521360940d3f7"

        if let signedTransaction = cereal.signEthereumTransactionWithWallet(hex: transactionSkeleton) {
            XCTAssertEqual(expectedSignedTransaction, signedTransaction)
        } else {
            XCTFail("Transaction signing failed")
        }
    }

    func testWithFullTransactionButNoNetworkId() {
        let transactionSkeleton = "0xe885746f6b6682832dc6c0832dc6c094dc0a63a5bdb165640661709569816bf08594dfd78080808080"
        let expectedSignedTransaction = "0xf86885746f6b6682832dc6c0832dc6c094dc0a63a5bdb165640661709569816bf08594dfd780801ca0f7afe4aa4d329056865ed31d1bf13765348495438bfdd66418de440bed3d626da012ae7c764b96bebcc9ef6b6c8f0dcc760b229f14c939adac42b521360940d3f7"
        if let signedTransaction = cereal.signEthereumTransactionWithWallet(hex: transactionSkeleton) {
            XCTAssertEqual(expectedSignedTransaction, signedTransaction)
        } else {
            XCTFail("Transaction signing failed")
        }
    }

    func testWithNetworkId() {
        let transactionSkeleton = "0xf86d85746f6b6682832dc6c0832dc6c094dc0a63a5bdb165640661709569816bf08594dfd780b844a9059cbb0000000000000000000000002278562760cf038cb33b7b405c295a4c50db4fdd00000000000000000000000000000000000000000000000000000002540be400748080"
        let expectedSignedTransaction = "0xf8af85746f6b6682832dc6c0832dc6c094dc0a63a5bdb165640661709569816bf08594dfd780b844a9059cbb0000000000000000000000002278562760cf038cb33b7b405c295a4c50db4fdd00000000000000000000000000000000000000000000000000000002540be40082010ca0cc36d85db2f86b4e4cb2eda96ebf7c4fdd1eef91928003bd746197a6eb1fc9aca024877d4fef27bc28faca098d47b1b722ef6e612717f023390c0071c547181935"
        if let signedTransaction = cereal.signEthereumTransactionWithWallet(hex: transactionSkeleton) {
            XCTAssertEqual(expectedSignedTransaction, signedTransaction)
        } else {
            XCTFail("Transaction signing failed")
        }
    }

    func testWithInvalidTransactionAndInvalidRLP() {
        let transactionSkeleton = "0xf86d8570be4007480801"
        XCTAssertNil(cereal.signEthereumTransactionWithWallet(hex: transactionSkeleton))
    }

    func testWithInvalidTransactionAndValidRLP() {
        let transactionSkeleton = "0xce85746f6b6682832dc6c0832dc6c0"
        XCTAssertNil(cereal.signEthereumTransactionWithWallet(hex: transactionSkeleton))

    }

    func testWalletQRCodeImage() {
        let expectedQRCodeImage = UIImage.imageQRCode(for: "ethereum:\(cereal.paymentAddress)", resizeRate: 20.0)
        let resultImage = cereal.walletAddressQRCodeImage(resizeRate: 20.0)

        guard let resultQRCodeImageData = UIImagePNGRepresentation(resultImage) else {
            XCTFail("Can't create result QR code image Data")
            return
        }

        if let expectedImageData = UIImagePNGRepresentation(expectedQRCodeImage) {
            XCTAssertEqual(expectedImageData, resultQRCodeImageData)
        } else {
            XCTFail("Wallet QR code image to Data convertion failed")
        }

        guard let resultString = resultImage.stringInQRCode else {
            XCTFail("Could not get string from image!")
            return
        }

        let expectedMessageString = "ethereum:0x9858effd232b4033e47d90003d41ec34ecaeda94"
        XCTAssertEqual(expectedMessageString, resultString)
    }
}
