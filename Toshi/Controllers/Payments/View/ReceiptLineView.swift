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

final class ReceiptLineView: UIStackView {

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.font = Theme.preferredRegular()
        titleLabel.textColor = Theme.lightGreyTextColor
        titleLabel.adjustsFontForContentSizeCategory = true

        return titleLabel
    }()

    private lazy var amountLabel: UILabel = {
        let amountLabel = UILabel()
        amountLabel.numberOfLines = 0
        amountLabel.font = Theme.preferredRegular()
        amountLabel.textColor = Theme.darkTextColor
        amountLabel.adjustsFontForContentSizeCategory = true
        amountLabel.textAlignment = .right

        return amountLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        axis = .horizontal

        addArrangedSubview(titleLabel)
        addArrangedSubview(amountLabel)

        amountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    func setValue(_ value: String) {
        amountLabel.text = value
    }
}
