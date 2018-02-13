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

/// An individual Collectible
final class Collectible: Codable {

    let name: String
    let value: String
    let contractAddress: String
    let icon: String
    let tokens: [CollectibleToken]?

    enum CodingKeys: String, CodingKey {
        case
        name,
        value,
        contractAddress = "contract_address",
        icon,
        tokens
    }
}

/// Convenience class for decoding an array of Collectibles with the key "collectibles"
final class CollectibleResults: Codable {

    let collectibles: [Collectible]

    enum CodingKeys: String, CodingKey {
        case
        collectibles
    }
}

extension Collectible: WalletItem {
    var title: String? {
        return name
    }

    var subtitle: String? {
        return nil
    }

    var iconPath: String? {
        return icon
    }

    var details: String? {
        return NSDecimalNumber(hexadecimalString: value).stringValue
    }
}
