import XCTest
import UIKit
@testable import Toshi

class EthereumAddressTests: XCTestCase {
    let canonicalAddress = "0x037be053f866be6ee6dda11f258bd871b701a8d7"

    func testHex() {
        var address = EthereumAddress(raw: canonicalAddress)?.normalized
        XCTAssertEqual(address, canonicalAddress)

        address = EthereumAddress(raw: "0x"+"037be053f866be6ee6dda11f258bd871b701a8d7".uppercased())?.normalized
        XCTAssertEqual(address, canonicalAddress)
    }

    func testEthereumHex() {
        let address = EthereumAddress(raw: "ethereum:0x037be053f866be6ee6dda11f258bd871b701a8d7")?.normalized
        XCTAssertEqual(address, canonicalAddress)
    }

    func testUnprefixedHex() {
        let address = EthereumAddress(raw: "037be053f866be6ee6dda11f258bd871b701a8d7")?.normalized
        XCTAssertEqual(address, canonicalAddress)
    }

    func testIcap() {
        let address = EthereumAddress(raw: "iban:XE420ENF06QHAD2B0729XZJ1OU26UVM0TSN")?.normalized
        XCTAssertEqual(address, canonicalAddress)
    }

    func testGarbage() {
        XCTAssertNil(EthereumAddress(raw: "A plague of locusts"))
        XCTAssertNil(EthereumAddress(raw: "0x037be053f866be6ee6"))
        XCTAssertNil(EthereumAddress(raw: "iban:xeabc123"))
        XCTAssertNil(EthereumAddress(raw: "💩"))
        XCTAssertNil(EthereumAddress(raw: "https://toshi.org/pay/mark"))
    }
}
