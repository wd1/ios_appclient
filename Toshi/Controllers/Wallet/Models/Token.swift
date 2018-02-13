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

/// An individual Token
final class Token: Codable {

    let name: String
    let symbol: String
    let value: String
    let decimals: Int
    let contractAddress: String
    let icon: String

    lazy var displayValueString: String = {
        let decimalNumberValue = NSDecimalNumber(hexadecimalString: self.value)
        var decimalValueString = decimalNumberValue.stringValue

        let valueFormatter = NumberFormatter()
        valueFormatter.numberStyle = .decimal

        guard self.decimals > 0 else { return decimalValueString }

        var insertionString = ""
        if decimalValueString.length == self.decimals {
            insertionString.append(valueFormatter.zeroSymbol ?? "0")
        }

        insertionString.append(valueFormatter.decimalSeparator ?? ".")

        let insertIndex = decimalValueString.index(decimalValueString.endIndex, offsetBy: -self.decimals)
        decimalValueString.insert(contentsOf: insertionString, at: insertIndex)

        return decimalValueString
    }()

    enum CodingKeys: String, CodingKey {
        case
        name,
        symbol,
        value,
        decimals,
        contractAddress = "contract_address",
        icon
    }
}

/// Convenience class for decoding an array of Token with the key "tokens"
final class TokenResults: Codable {

    let tokens: [Token]

    enum CodingKeys: String, CodingKey {
        case
        tokens
    }
}

extension Token: WalletItem {
    var title: String? {
        return name
    }
    
    var subtitle: String? {
        return symbol
    }
    
    var iconPath: String? {
        return icon
    }
    
    var details: String? {
        return displayValueString
    }
}
