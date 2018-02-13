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
import EtherealCereal
@testable import Toshi

class RLPTests: XCTestCase {

    func testEmptyString() {

        let decoded = ""
        let encoded = "80"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testShortString() {
        let decoded = "dog"
        let encoded = "83646f67"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testShortString2() {
        let decoded = "Lorem ipsum dolor sit amet, consectetur adipisicing eli"
        let encoded = "b74c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c69"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testLongString() {
        let decoded = "Lorem ipsum dolor sit amet, consectetur adipisicing elit"
        let encoded = "b8384c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c6974"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testLongString2() {
        let decoded = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur mauris magna, suscipit sed vehicula non, iaculis faucibus tortor. Proin suscipit ultricies malesuada. Duis tortor elit, dictum quis tristique eu, ultrices at risus. Morbi a est imperdiet mi ullamcorper aliquet suscipit nec lorem. Aenean quis leo mollis, vulputate elit varius, consequat enim. Nulla ultrices turpis justo, et posuere urna consectetur nec. Proin non convallis metus. Donec tempor ipsum in mauris congue sollicitudin. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Suspendisse convallis sem vel massa faucibus, eget lacinia lacus tempor. Nulla quis ultricies purus. Proin auctor rhoncus nibh condimentum mollis. Aliquam consequat enim at metus luctus, a eleifend purus egestas. Curabitur at nibh metus. Nam bibendum, neque at auctor tristique, lorem libero aliquet arcu, non interdum tellus lectus sit amet eros. Cras rhoncus, metus ac ornare cursus, dolor justo ultrices metus, at ullamcorper volutpat"
        let encoded = "b904004c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742e20437572616269747572206d6175726973206d61676e612c20737573636970697420736564207665686963756c61206e6f6e2c20696163756c697320666175636962757320746f72746f722e2050726f696e20737573636970697420756c74726963696573206d616c6573756164612e204475697320746f72746f7220656c69742c2064696374756d2071756973207472697374697175652065752c20756c7472696365732061742072697375732e204d6f72626920612065737420696d70657264696574206d6920756c6c616d636f7270657220616c6971756574207375736369706974206e6563206c6f72656d2e2041656e65616e2071756973206c656f206d6f6c6c69732c2076756c70757461746520656c6974207661726975732c20636f6e73657175617420656e696d2e204e756c6c6120756c74726963657320747572706973206a7573746f2c20657420706f73756572652075726e6120636f6e7365637465747572206e65632e2050726f696e206e6f6e20636f6e76616c6c6973206d657475732e20446f6e65632074656d706f7220697073756d20696e206d617572697320636f6e67756520736f6c6c696369747564696e2e20566573746962756c756d20616e746520697073756d207072696d697320696e206661756369627573206f726369206c756374757320657420756c74726963657320706f737565726520637562696c69612043757261653b2053757370656e646973736520636f6e76616c6c69732073656d2076656c206d617373612066617563696275732c2065676574206c6163696e6961206c616375732074656d706f722e204e756c6c61207175697320756c747269636965732070757275732e2050726f696e20617563746f722072686f6e637573206e69626820636f6e64696d656e74756d206d6f6c6c69732e20416c697175616d20636f6e73657175617420656e696d206174206d65747573206c75637475732c206120656c656966656e6420707572757320656765737461732e20437572616269747572206174206e696268206d657475732e204e616d20626962656e64756d2c206e6571756520617420617563746f72207472697374697175652c206c6f72656d206c696265726f20616c697175657420617263752c206e6f6e20696e74657264756d2074656c6c7573206c65637475732073697420616d65742065726f732e20437261732072686f6e6375732c206d65747573206163206f726e617265206375727375732c20646f6c6f72206a7573746f20756c747269636573206d657475732c20617420756c6c616d636f7270657220766f6c7574706174"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testLongString3() {
        let encoded = "ba010000\(String(repeating: "78", count: 65536))"
        let decoded = String(repeating: "x", count: 65536)

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testZero() {
        let decoded: UInt32 = 0
        let encoded = "80"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testSmallInt() {
        let decoded: UInt32 = 1
        let encoded = "01"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testSmallInt2() {
        let decoded: UInt32 = 16
        let encoded = "10"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testSmallInt3() {
        let decoded: UInt32 = 79
        let encoded = "4f"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testSmallInt4() {
        let decoded: UInt32 = 127
        let encoded = "7f"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testMediumInt() {
        let decoded: UInt32 = 128
        let encoded = "8180"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testMediumInt2() {
        let decoded: UInt32 = 1000
        let encoded = "8203e8"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testMediumInt3() {
        let decoded: UInt32 = 100000
        let encoded = "830186a0"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testMediumInt4() {
        let decoded = "0x102030405060708090a0b0c0d0e0f2".hexadecimalData!
        let encoded = "8f102030405060708090a0b0c0d0e0f2"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testMediumInt5() {
        let decoded = "0x0100020003000400050006000700080009000a000b000c000d000e01".hexadecimalData!
        let encoded = "9c0100020003000400050006000700080009000a000b000c000d000e01"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testEmptyList() {
        let decoded: [Any] = []
        let encoded = "c0"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testStringList() {
        let decoded: [Any] = [ "dog", "god", "cat" ]
        let encoded = "cc83646f6783676f6483636174"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testMultiList() {
        let decoded: [Any] = [ "zw", [ UInt32(4) ], UInt32(1) ]
        let encoded = "c6827a77c10401"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testShortListMax1() {
        let decoded: [Any] = [ "asdf", "qwer", "zxcv", "asdf", "qwer", "zxcv", "asdf", "qwer", "zxcv", "asdf", "qwer"]
        let encoded = "f784617364668471776572847a78637684617364668471776572847a78637684617364668471776572847a78637684617364668471776572"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testLongList1() {
        let decoded: [Any] = [
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"]
        ]
        let encoded = "f840cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testLongList2() {
        let decoded: [Any] = [
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"],
          ["asdf", "qwer", "zxcv"]
        ]
        let encoded = "f90200cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testListOfLists() {
        let decoded: [Any] = [ [ [], [] ], [] ]
        let encoded = "c4c2c0c0c0"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testListOfLists2() {
        let decoded: [Any] = [ [], [[]], [ [], [[]] ] ]
        let encoded = "c7c0c1c0c3c0c1c0"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testDictTest1() {
        let decoded: [Any] = [
          ["key1", "val1"],
          ["key2", "val2"],
          ["key3", "val3"],
          ["key4", "val4"]
        ]
        let encoded = "ecca846b6579318476616c31ca846b6579328476616c32ca846b6579338476616c33ca846b6579348476616c34"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testBigint() {
        let decoded = "0x010000000000000000000000000000000000000000000000000000000000000000".hexadecimalData!
        let encoded = "a1010000000000000000000000000000000000000000000000000000000000000000"

        doDecodeTest(encoded, decoded)
        doEncodeTest(decoded, encoded)
    }

    func testInvalidRLP() {

        let invalidRlp: [(Any, RLP.RLPDecodeError)] = [
            (Data(capacity: 0), RLP.RLPDecodeError.stringTooShort),
            ("00ab", RLP.RLPDecodeError.stringEndsWithSuperfluousBytes),
            ("0000ff", RLP.RLPDecodeError.stringEndsWithSuperfluousBytes),
            ("83dogcat", RLP.RLPDecodeError.invalidHexString),
            ("83do", RLP.RLPDecodeError.invalidHexString),
            ("c7c0c1c0c3c0c1c0ff", RLP.RLPDecodeError.stringEndsWithSuperfluousBytes),
            ("c7c0c1c0c3c0c1", RLP.RLPDecodeError.stringTooShort),
            ("8102", RLP.RLPDecodeError.encodedAsShortStringAlthoughSingleByteWasPossible),
            ("b80000", RLP.RLPDecodeError.lengthStartsWithZeroBytes),
            ("b9000000", RLP.RLPDecodeError.lengthStartsWithZeroBytes),
            ("ba0002ffff", RLP.RLPDecodeError.lengthStartsWithZeroBytes),
            ("8154", RLP.RLPDecodeError.encodedAsShortStringAlthoughSingleByteWasPossible),
            ("81", RLP.RLPDecodeError.stringTooShort),
            ("bf", RLP.RLPDecodeError.stringTooShort),
            ("bf38", RLP.RLPDecodeError.stringTooShort),
            ("f9", RLP.RLPDecodeError.stringTooShort),
            ("f938", RLP.RLPDecodeError.stringTooShort)
        ]

        for (input, expectedError) in invalidRlp {
            do {
                if let data = input as? Data {
                    _ = try RLP.decode(from: data)
                } else if let hex = input as? String {
                    _ = try RLP.decode(from: hex)
                } else {
                    XCTFail("Unexpected input type")
                }
                XCTFail("Expected Failure!")
            } catch let error {
                if let error = error as? RLP.RLPDecodeError {
                    XCTAssertEqual(error, expectedError, "Expected different failure for input: \(input)")
                } else {
                    XCTFail("Unexpected Error")
                }
            }
        }
    }

    private func doDecodeTest(_ input: String, _ expected: String) {
        do {
            let result = try RLP.decode(from: input)
            if let data = result as? Data {
                let str = String(data: data, encoding: .utf8)
                XCTAssertEqual(str, expected)
            } else {
                XCTFail("Expected Data result")
            }
        } catch {
            XCTFail("Decoding Error")
        }
    }

    private func doDecodeTest(_ input: String, _ expected: UInt32) {
        do {
            let result = try RLP.decode(from: input)
            if let data = result as? Data,
               let val = UInt32(bigEndianData: data) {
                XCTAssertEqual(val, expected)
            } else {
                XCTFail("Expected Data result")
            }
        } catch {
            XCTFail("Decoding Error")
        }
    }

    private func doDecodeTest(_ input: String, _ expected: Data) {
        do {
            let result = try RLP.decode(from: input)
            if let data = result as? Data {
                XCTAssertEqual(data, expected)
            } else {
                XCTFail("Expected Data result")
            }
        } catch {
            XCTFail("Decoding Error")
        }
    }

    private func doDecodeTest(_ input: String, _ expected: [Any]) {
        do {
            let result = try RLP.decode(from: input)
            if let list = result as? [Any] {
                recursiveCheck(expected, list)
            } else {
                XCTFail("Decode returned unexpected type")
            }
        } catch {
            XCTFail("Decoding Error")
        }
    }

    private func recursiveCheck(_ expectedList: [Any], _ resultList: [Any]) {
        XCTAssertEqual(expectedList.count, resultList.count)
        for (expected, result) in zip(expectedList, resultList) {
            if let expected = expected as? [Any] {
                guard let list = result as? [Any] else {
                    XCTFail("Expected list")
                    return
                }
                recursiveCheck(expected, list)
            } else {
                if let result = result as? Data {
                    if let expected = expected as? Data {
                        XCTAssertEqual(result, expected)
                    } else if let expected = expected as? String {
                        let str = String(data: result, encoding: .utf8)
                        XCTAssertEqual(str, expected)
                    } else if let expected = expected as? UInt32,
                        let val = UInt32(bigEndianData: result) {
                        XCTAssertEqual(val, expected)
                    } else {
                        XCTFail("Unexpected type")
                    }
                } else {
                    XCTFail("List element is not Data")
                }
            }
        }
    }

    private func doEncodeTest(_ input: Any, _ expected: String) {
        do {
            let result = try RLP.encode(input).hexEncodedString()
            XCTAssertEqual(result, expected)
        } catch {
            XCTFail("Encoding Error")
        }
    }
}
