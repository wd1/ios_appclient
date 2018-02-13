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

extension NSDecimalNumber {

    static var weiRoundingBehavior: NSDecimalNumberHandler {
        return NSDecimalNumberHandler(roundingMode: .up, scale: EthereumConverter.weisToEtherPowerOf10Constant, raiseOnExactness: false, raiseOnOverflow: true, raiseOnUnderflow: true, raiseOnDivideByZero: true)
    }

    var toDecimalString: String {
        return String(describing: self)
    }

    var toHexString: String {
        return "0x\(BaseConverter.decToHex(toDecimalString).lowercased())"
    }

    var isANumber: Bool {
        return self != .notANumber
    }

    convenience init(hexadecimalString hexString: String) {
        var hexString = hexString.replacingOccurrences(of: "0x", with: "")

        // First we perform some sanity checks on the string. Then we chop it in 8 pieces and convert each to a UInt32.
        assert(!hexString.isEmpty, "Can't be empty")

        // Assert if string isn't too long
        assert(hexString.count <= 64, "Too large")

        hexString = hexString.uppercased()

        // Assert if string has any characters that are not 0-9 or A-F
        for character in hexString {
            switch character {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F":
                assert(true)
            default:
                assert(false, "Invalid character")
            }
        }

        // Pad zeros
        if hexString.count < 64 {
            for _ in 1 ... (64 - hexString.count) {
                hexString = "0" + hexString
            }
        }

        let decimal = BaseConverter.hexToDec(hexString)

        self.init(string: decimal)
    }

    func isGreaterOrEqualThan(value: NSDecimalNumber) -> Bool {
        let result = compare(value)

        switch result {
        case .orderedDescending, .orderedSame:
                return true
        case .orderedAscending:
                return false
        }
    }

    func isGreaterThan(value: NSDecimalNumber) -> Bool {
        let result = compare(value)

        switch result {
        case .orderedDescending:
                return true
        case .orderedAscending, .orderedSame:
                return false
        }
    }
}
