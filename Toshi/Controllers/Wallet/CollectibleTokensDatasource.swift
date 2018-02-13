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

import UIKit

protocol CollectibleTokensDatasourceDelegate: class {
    func collectibleDatasourceDidReloadl(_ datasource: CollectibleTokensDatasource)
}

final class CollectibleTokensDatasource {

    weak var delegate: CollectibleTokensDatasourceDelegate?

    private let collectibleTokenAddress: String
    private var collectible: Collectible?

    var name: String? {
        return collectible?.name
    }

    var tokens: [CollectibleToken]? {
        return collectible?.tokens
    }

    func token(at index: Int) -> CollectibleToken? {
        let tokensCount = collectible?.tokens?.count ?? 0
        guard index < tokensCount else {
            assertionFailure("Attempting to access token at invalid index")
            return nil
        }

        return collectible?.tokens?[index]
    }

    init(collectibleContractAddress: String) {
        self.collectibleTokenAddress = collectibleContractAddress
        loadCollectibleDetails()
    }

    private func loadCollectibleDetails() {

        EthereumAPIClient.shared.getCollectible(contractAddress: collectibleTokenAddress) { [weak self] collectible, error in
            guard let strongSelf = self else { return }

            guard error == nil else {
                strongSelf.showErrorAlert(error!)
                return
            }

            strongSelf.collectible = collectible

            strongSelf.delegate?.collectibleDatasourceDidReloadl(strongSelf)
        }
    }

    private func showErrorAlert(_ error: ToshiError) {
        let alertController = UIAlertController.dismissableAlert(title: Localized("toshi_generic_error"), message: error.description)
        Navigator.presentModally(alertController)
    }
}
