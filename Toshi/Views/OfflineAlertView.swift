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
import SweetUIKit

class OfflineAlertView: UIView {
    static let height: CGFloat = 32.0
    private let margin: CGFloat = 6.0

    let displayTransform = CGAffineTransform(translationX: 0, y: -OfflineAlertView.height)
    var heightConstraint: NSLayoutConstraint?

    private lazy var textLabel: UILabel = {
        let textLabel = UILabel()

        textLabel.font = Theme.regular(size: 14)
        textLabel.textColor = Theme.lightTextColor
        textLabel.textAlignment = .center

        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.8

        textLabel.text = Localized("offline_alert_message")

        return textLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupView()
    }

    func setupView() {
        backgroundColor = Theme.offlineAlertBackgroundColor.withAlphaComponent(0.98)

        addSubview(textLabel)
        textLabel.edges(to: self, insets: UIEdgeInsets(top: 0, left: margin, bottom: 0, right: -margin))

        height(OfflineAlertView.height)
    }
}
