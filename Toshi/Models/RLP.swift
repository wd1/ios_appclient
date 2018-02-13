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

/// Implementation of RLP (Recursive Length Prefix) encoding and decoding
/// <https://github.com/ethereum/wiki/wiki/RLP>
class RLP {

    enum RLPDataType {
        case string
        case list
    }

    enum RLPDecodeError: Error {
        case invalidHexString
        case encodedAsShortStringAlthoughSingleByteWasPossible
        case lengthStartsWithZeroBytes
        case longStringPrefixUsedForShortString
        case longListPrefixUsedForShortList
        case listLengthPrefixTooSmall
        case stringTooShort
        case stringEndsWithSuperfluousBytes
        case unsupportedIntegerSize
    }

    enum RLPEncodeError: Error {
        case unsupportedDataType
        case lengthGreaterThanMax
    }

    static func decode(from hex: String) throws -> Any {
        guard let data = hex.hexadecimalData else {
            throw RLPDecodeError.invalidHexString
        }

        do {
            return try decode(from: data)
        } catch let error {
            throw error
        }
    }

    static func decode(from data: Data) throws -> Any {
        do {
            let (item, end) = try consumeItem(data, 0)
            if end != data.count {
                throw RLPDecodeError.stringEndsWithSuperfluousBytes
            }
            return item
        } catch let error {
            throw error
        }
    }

    private static func consumeItem(_ rlp: Data, _ start: UInt) throws -> (Any, UInt) {
        do {
            let (type, length, start) = try consumeLengthPrefix(rlp, start)
            return try consumePayload(rlp, type, length, start)
        } catch let error {
            throw error
        }
    }

    private static func consumePayload(_ rlp: Data, _ type: RLPDataType, _ length: UInt, _ start: UInt) throws -> (Any, UInt) {
        switch type {
        case .string:
            if rlp.count < start + length {
                throw RLPDecodeError.stringTooShort
            }
            let string: Data
            if length == 0 {
                string = Data(capacity: 0)
            } else {
                string = Data(rlp[start..<start + length])
            }
            return (string, start + length)
        case .list:
            var items: [Any] = []
            var nextItemStart = start
            let end = nextItemStart + length
            while nextItemStart < end {
                let item: Any
                do {
                    (item, nextItemStart) = try consumeItem(rlp, nextItemStart)
                } catch let error {
                    throw error
                }
                items.append(item)
            }
            if nextItemStart > end {
                throw RLPDecodeError.listLengthPrefixTooSmall
            }
            return (items, nextItemStart)
        }
    }

    // This method has a lot of short variable names. I've done this on purpose as I find it easier to parse
    // most of the syntax lines easier to parse with the short names. Longer names just make it too verbose.
    // Common variable naming:
    //  - b0 : Byte Zero
    //  - start : The start of the current length prefix
    //  - length : The length of the item the current length prefix describes
    //  - ll : "Length length", the length of the current length prefix field
    // returns (item type, item length, item start offset)
    private static func consumeLengthPrefix(_ rlp: Data, _ start: UInt) throws -> (RLPDataType, UInt, UInt) { //swiftlint:disable:this large_tuple
        if rlp.count <= start {
            throw RLPDecodeError.stringTooShort
        }
        let b0 = UInt(UInt8(rlp[Int(start)]))
        if b0 < 128 { // single byte
            return (.string, 1, start)
        } else if b0 < 128 + 56 { // short string
            if b0 - 128 == 1 {
                if rlp.count <= start + 1 {
                    throw RLPDecodeError.stringTooShort
                } else if rlp[Int(start) + 1] < 128 {
                    throw RLPDecodeError.encodedAsShortStringAlthoughSingleByteWasPossible
                }
            }
            return (.string, b0 - 128, start + 1)
        } else if b0 < 192 { // long string
            let ll = b0 - 128 - 56 + 1
            if rlp.count <= start + 1 + ll {
                throw RLPDecodeError.stringTooShort
            }
            if rlp[Int(start) + 1] == 0 {
                throw RLPDecodeError.lengthStartsWithZeroBytes
            }
            guard let length = UInt(bigEndianData: rlp[start + 1..<start + 1 + ll]) else {
                throw RLPDecodeError.unsupportedIntegerSize
            }
            if length < 56 {
                throw RLPDecodeError.longStringPrefixUsedForShortString
            }
            return (.string, length, start + 1 + ll)
        } else if b0 < 192 + 56 {
            return (.list, b0 - 192, start + 1)
        } else {
            let ll = b0 - 192 - 56 + 1
            if rlp.count <= start + 1 + ll {
                throw RLPDecodeError.stringTooShort
            }
            if rlp[Int(start) + 1] == 0 {
                throw RLPDecodeError.lengthStartsWithZeroBytes
            }
            guard let length = UInt(bigEndianData: rlp[start + 1..<start + 1 + ll]) else {
                throw RLPDecodeError.unsupportedIntegerSize
            }
            if length < 56 {
                throw RLPDecodeError.longListPrefixUsedForShortList
            }
            return (.list, length, start + 1 + ll)
        }
    }

    static func encode(_ obj: Any) throws -> Data {
        let bytes: Data
        let prefixOffset: UInt8

        if let list = obj as? [Any] {
            do {
                bytes = try Data(list.map { try encode($0) }.flatMap { $0 })
            } catch let err {
                throw err
            }
            prefixOffset = 192
        } else {
            if let uint8 = obj as? UInt8 {
                bytes = Data(bigEndianFrom: uint8)
            } else if let uint16 = obj as? UInt16 {
                bytes = Data(bigEndianFrom: uint16)
            } else if let uint32 = obj as? UInt32 {
                bytes = Data(bigEndianFrom: uint32)
            } else if let uint64 = obj as? UInt64 {
                bytes = Data(bigEndianFrom: uint64)
            } else if let str = obj as? String {
                guard let temp = str.data(using: .utf8) else {
                    throw RLPEncodeError.unsupportedDataType
                }
                bytes = temp
            } else if let data = obj as? Data {
                bytes = data
            } else {
                throw RLPEncodeError.unsupportedDataType
            }

            if bytes.count == 1 && bytes[0] < 128 {
                return bytes
            }

            prefixOffset = 128
        }

        do {
            let prefix = try lengthPrefix(UInt(bytes.count), prefixOffset)
            return prefix + bytes
        } catch let err {
            throw err
        }
    }

    private static func lengthPrefix(_ length: UInt, _ offset: UInt8) throws -> Data {
        if length < 56 {
            return Data([offset + UInt8(length)])
        } else if length < UInt.max {
            let lengthString = Data(bigEndianFrom: length)
            return Data([offset + 56 - 1 + UInt8(lengthString.count)]) + lengthString
        } else {
            throw RLPEncodeError.lengthGreaterThanMax
        }
    }

}

extension Data {

    init<T: FixedWidthInteger>(bigEndianFrom value: T) {
        if value == 0 {
            self.init()
            return
        }
        var value = value.bigEndian
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
        if let paddingIndex = self.index(where: { $0 != 0 }) {
            self.removeSubrange(0..<Int(paddingIndex))
        } else {
            self.removeAll()
        }
    }

}

protocol BigEndianDataConvertible {
    init?(bigEndianData: Data)
}

extension BigEndianDataConvertible where Self:FixedWidthInteger {
    init?(bigEndianData: Data) {
        let padding = MemoryLayout<Self>.size - bigEndianData.count
        let paddedBigEndianData: Data
        if padding > 0 {
            paddedBigEndianData = Data(count: padding) + bigEndianData
        } else {
            paddedBigEndianData = Data(bigEndianData)
        }
        self.init(bigEndian: paddedBigEndianData.withUnsafeBytes { $0.pointee })
    }
}

extension UInt8: BigEndianDataConvertible {}
extension UInt16: BigEndianDataConvertible {}
extension UInt32: BigEndianDataConvertible {}
extension UInt64: BigEndianDataConvertible {}
extension UInt: BigEndianDataConvertible {}

extension Data {

    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }

}
