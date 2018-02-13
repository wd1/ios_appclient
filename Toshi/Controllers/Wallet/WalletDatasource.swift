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

typealias WalletItemResults = (_ apps: [WalletItem]?, _ error: ToshiError?) -> Void

enum WalletItemType: Int {
    case token
    case collectibles
}

protocol WalletDatasourceDelegate: class {
    func walletDatasourceDidReload()
}

final class WalletDatasource {

    weak var delegate: WalletDatasourceDelegate?

    var itemsType: WalletItemType = .token {
        didSet {
            loadItems()
        }
    }

    private var items: [WalletItem] = []

    init(delegate: WalletDatasourceDelegate?) {
        self.delegate = delegate
    }

    var numberOfItems: Int {
        return items.count
    }

    var isEmpty: Bool {
        return numberOfItems == 0
    }

    var emptyStateTitle: String {
        switch itemsType {
        case .token:
            return Localized("wallet_empty_tokens_title")
        case .collectibles:
            return Localized("wallet_empty_collectibles_title")
        }
    }

    func item(at index: Int) -> WalletItem? {
        guard index < items.count else {
            assertionFailure("Failed retrieve wallet item due to invalid index: \(index)")
            return nil
        }

        return items[index]
    }

    func loadItems() {
        switch itemsType {
        case .token:
            loadTokens()
        case .collectibles:
            loadCollectibles()
        }
    }

    private func loadTokens() {
        EthereumAPIClient.shared.getTokens { [weak self] items, _ in
            self?.items = items
            self?.delegate?.walletDatasourceDidReload()
        }
    }
    
    private func loadCollectibles() {
        EthereumAPIClient.shared.getCollectibles { [weak self] items, _ in
            self?.items = items
            self?.delegate?.walletDatasourceDidReload()
        }
    }
}
