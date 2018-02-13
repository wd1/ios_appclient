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

class QRCodeGeneratorTests: XCTestCase {

    func testCreatingAddUserQRCode() {
        let qrCodeImage = QRCodeGenerator.qrCodeImage(for: .addUser(username: "HomerSimpson"))
        guard let stringFromCode = qrCodeImage.stringInQRCode else {
            XCTFail("Could not get string from QR code!")
            return
        }

        let expectedString = "https://app.toshi.org/add/HomerSimpson"
        XCTAssertEqual(stringFromCode, expectedString)
    }

    func testCreatingEthereumAddressQRCode() {
        let qrCodeImage = QRCodeGenerator.qrCodeImage(for: .ethereumAddress(address: "0xSeemsLegit"))
        guard let stringFromCode = qrCodeImage.stringInQRCode else {
            XCTFail("Could not get string from QR code!")
            return
        }

        let expectedString = "ethereum:0xSeemsLegit"
        XCTAssertEqual(stringFromCode, expectedString)
    }
}
