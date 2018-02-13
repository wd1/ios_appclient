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

final class CollectibleViewController: UIViewController {

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = nil
        view.register(RectImageTitleSubtitleTableViewCell.self)
        view.delegate = self
        view.dataSource = self
        view.tableFooterView = UIView()
        view.layer.borderWidth = .lineHeight
        view.layer.borderColor = Theme.borderColor.cgColor
        view.alwaysBounceVertical = true

        return view
    }()

    var collectibleContractAddress: String
    var datasource: CollectibleTokensDatasource

    init(collectibleContractAddress: String) {
        self.collectibleContractAddress = collectibleContractAddress
        self.datasource = CollectibleTokensDatasource(collectibleContractAddress: collectibleContractAddress)

        super.init(nibName: nil, bundle: nil)

        datasource.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.viewBackgroundColor
        addSubviewsAndConstraints()
    }

    private func addSubviewsAndConstraints() {
        view.addSubview(tableView)
        tableView.edges(to: view)
    }
}

extension CollectibleViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension CollectibleViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.tokens?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let token = datasource.token(at: indexPath.row) else {
            assertionFailure("Can't find token at a given index path")
            return UITableViewCell()
        }

        let cell = tableView.dequeue(RectImageTitleSubtitleTableViewCell.self, for: indexPath)
        cell.titleLabel.text = token.name
        cell.subtitleLabel.text = token.description

        AvatarManager.shared.avatar(for: token.image, completion: { image, path in
            if token.image == path {
                cell.leftImageView.image = image
            }
        })

        return cell
    }
}

extension CollectibleViewController: CollectibleTokensDatasourceDelegate {

    func collectibleDatasourceDidReloadl(_ datasource: CollectibleTokensDatasource) {
        tableView.reloadData()
        title = datasource.name
    }
}
