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

final class WalletViewController: UIViewController, Emptiable {

    private let walletHeaderHeight: CGFloat = 180
    private let sectionHeaderHeight: CGFloat = 44

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = nil
        BasicTableViewCell.register(in: view)
        view.delegate = self
        view.dataSource = self
        view.tableFooterView = UIView()
        view.layer.borderWidth = .lineHeight
        view.layer.borderColor = Theme.borderColor.cgColor
        view.alwaysBounceVertical = true

        return view
    }()

    private lazy var tableHeaderView: UIView = {
        let walletItemTitles = [Localized("wallet_tokens"), Localized("wallet_collectibles")]
        let headerView = SegmentedHeaderView(segmentNames: walletItemTitles, delegate: self)
        headerView.backgroundColor = Theme.viewBackgroundColor

        return headerView
    }()

    private lazy var datasource = WalletDatasource(delegate: self)

    let emptyView = EmptyView(title: Localized("wallet_empty_tokens_title"), description: Localized("wallet_empty_tokens_description"), buttonTitle: Localized("wallet_empty_tokens_button_title"))

    override func viewDidLoad() {
        super.viewDidLoad()

        emptyView.isHidden = true

        title = Localized("wallet_controller_title")
        view.backgroundColor = Theme.lightGrayBackgroundColor

        addSubviewsAndConstraints()

        preferLargeTitleIfPossible(false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        datasource.loadItems()
    }

    private func addSubviewsAndConstraints() {
        view.addSubview(tableView)
        tableView.edges(to: view)

        let frame = CGRect(origin: .zero, size: CGSize(width: tableView.bounds.width, height: walletHeaderHeight))

        let headerView = WalletTableHeaderView(frame: frame,
                                               address: Cereal.shared.paymentAddress,
                                               delegate: self)
        tableView.tableHeaderView = headerView

        view.addSubview(emptyView)
        emptyView.actionButton.addTarget(self, action: #selector(emptyViewButtonPressed(_:)), for: .touchUpInside)
        emptyView.edges(to: layoutGuide(), insets: UIEdgeInsets(top: walletHeaderHeight + sectionHeaderHeight, left: 0, bottom: 0, right: 0))
    }

    @objc func emptyViewButtonPressed(_ button: ActionButton) {
        let qrCodeImage = Cereal.shared.walletAddressQRCodeImage(resizeRate: 20.0)
        shareWithSystemSheet(item: qrCodeImage)
    }

    private func adjustEmptyStateView() {
        emptyView.isHidden = !datasource.isEmpty
        emptyView.title = datasource.emptyStateTitle
    }
}

extension WalletViewController: ClipboardCopying { /* mix-in */ }
extension WalletViewController: SystemSharing { /* mix-in */ }

extension WalletViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.numberOfItems
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableHeaderView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let walletItem = datasource.item(at: indexPath.row) else {
            assertionFailure("Can't retrieve item at index: \(indexPath.row)")
            return UITableViewCell()
        }

        var cellData: TableCellData!

        switch datasource.itemsType {
        case .token:
            cellData = TableCellData(title: walletItem.title, subtitle: walletItem.subtitle, leftImagePath: walletItem.iconPath, topDetails: walletItem.details)
        case .collectibles:
            cellData = TableCellData(title: walletItem.title, subtitle: walletItem.subtitle, leftImagePath: walletItem.iconPath, details: walletItem.details)
        }

        let configurator = WalletItemCellConfigurator()
        let reuseIdentifier = configurator.cellIdentifier(for: cellData.components)

        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? BasicTableViewCell else {
            assertionFailure("Can't dequeue basic cell on wallet view controller for given reuse identifier: \(reuseIdentifier)")
            return UITableViewCell()
        }

        configurator.configureCell(cell, with: cellData)
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

extension WalletViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = datasource.item(at: indexPath.row) as? Collectible else { return }

        let controller = CollectibleViewController(collectibleContractAddress: item.contractAddress)
        navigationController?.pushViewController(controller, animated: true)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension WalletViewController: SegmentedHeaderDelegate {

    func segmentedHeader(_: SegmentedHeaderView, didSelectSegmentAt index: Int) {
        guard let itemType = WalletItemType(rawValue: index) else {
            assertionFailure("Can't create wallet item with given selected index: \(index)")
            return
        }

        datasource.itemsType = itemType
    }
}

extension WalletViewController: WalletDatasourceDelegate {

    func walletDatasourceDidReload() {
        adjustEmptyStateView()
        tableView.reloadData()
    }
}

extension WalletViewController: WalletTableViewHeaderDelegate {

    func copyAddress(_ address: String, from headerView: WalletTableHeaderView) {
        copyToClipboardWithGenericAlert(address)
    }

    func openAddress(_ address: String, from headerView: WalletTableHeaderView) {
        let qrController = WalletQRCodeViewController(address: address)
        self.present(qrController, animated: true)
    }
}
