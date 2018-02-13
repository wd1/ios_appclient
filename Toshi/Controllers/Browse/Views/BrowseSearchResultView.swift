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
import SweetFoundation
import UIKit

protocol SearchSelectionDelegate: class {

    func didSelectSearchResult(user: TokenUser)
}

class BrowseSearchResultView: UITableView {

    var searchResults: [TokenUser] = [] {
        didSet {
            reloadData()
        }
    }

    weak var searchDelegate: SearchSelectionDelegate?

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)

        backgroundColor = Theme.viewBackgroundColor

        dataSource = self
        delegate = self
        separatorStyle = .none
        alwaysBounceVertical = true
        showsVerticalScrollIndicator = true
        contentInset.bottom = 60

        register(SearchResultCell.self)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
}

extension BrowseSearchResultView: UITableViewDelegate {

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = searchResults.element(at: indexPath.row) {
            searchDelegate?.didSelectSearchResult(user: item)
        }
    }
}

extension BrowseSearchResultView: UITableViewDataSource {
	
    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(SearchResultCell.self, for: indexPath)

        if let item = searchResults.element(at: indexPath.row) {
            cell.usernameLabel.text = item.isApp ? item.category : item.username
            cell.nameLabel.text = item.name
            
            AvatarManager.shared.avatar(for: item.avatarPath, completion: { image, path in
                if item.avatarPath == path {
                    cell.avatarImageView.image = image
                }
            })
        }

        return cell
    }
}
