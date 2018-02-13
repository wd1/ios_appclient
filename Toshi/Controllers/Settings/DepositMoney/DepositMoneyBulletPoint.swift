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
import TinyConstraints

class DepositMoneyBulletPoint: UIView {

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.preferredSemibold()
        view.textColor = Theme.darkTextColor
        view.numberOfLines = 0
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    private lazy var textLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.preferredRegular()
        view.textColor = Theme.darkTextColor
        view.numberOfLines = 0
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    convenience init(title: String, text: String) {
        self.init()

        titleLabel.text = title
        addSubview(titleLabel)

        textLabel.text = text
        addSubview(textLabel)

        titleLabel.top(to: self, offset: 15)
        titleLabel.left(to: self, offset: 15)
        titleLabel.right(to: self, offset: -15)

        textLabel.topToBottom(of: titleLabel, offset: 5)
        textLabel.left(to: self, offset: 15)
        textLabel.right(to: self, offset: -15)
        textLabel.bottom(to: self)
    }
}
