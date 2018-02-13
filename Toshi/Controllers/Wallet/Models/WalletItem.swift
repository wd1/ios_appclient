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

enum WalletItemConstants {
    static let name = "name"
    static let symbol = "symbol"
    static let value = "value"
    static let contractAddress = "contract_address"
    static let icon = "icon"
    static let tokens = "tokens"
    static let decimals = "decimals"
    
}

protocol WalletItem {
    var title: String? { get }
    var subtitle: String? { get }
    var iconPath: String? { get }
    var details: String? { get }
}
