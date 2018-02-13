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

enum DepositMoneyItem {
    case header(String) // text
    case copyToClipBoard(String, String, Selector) // title, confirmation and action
    case QRCode(UIImage) // QR-Code image
    case warning(String) // red text label
    case bulletPoint(String, String) // title and text
}

extension DepositMoneyItem {

    var view: UIView {

        switch self {
        case .header(let text):
            let view = DepositMoneyHeader(text: text)

            return view

        case .copyToClipBoard(let title, let confirmation, let action):
            let container = UIView()

            let view = ConfirmationButton()
            view.title = title
            view.confirmation = confirmation
            view.addTarget(self, action: action, for: .touchUpInside)
            container.addSubview(view)

            view.top(to: container)
            view.left(to: container, offset: 15)
            view.bottom(to: container)

            return container

        case .QRCode(let image):
            let container = UIView()

            let view = UIImageView(image: image)
            view.contentMode = .scaleAspectFit
            container.addSubview(view)

            view.size(CGSize(width: 210, height: 210))
            view.centerX(to: container)
            view.top(to: container)
            view.bottom(to: container)

            return container

        case .warning(let warning):
            let container = UIView()

            let view = UILabel()
            view.text = warning
            view.font = Theme.preferredRegular()
            view.textColor = Theme.errorColor
            view.numberOfLines = 0
            view.adjustsFontForContentSizeCategory = true
            container.addSubview(view)

            view.edges(to: container, insets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: -15))

            return container

        case .bulletPoint(let title, let text):
            return DepositMoneyBulletPoint(title: title, text: text)
        }
    }
}

extension UIStackView {

    convenience init(with items: [DepositMoneyItem]) {
        self.init()

        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        spacing = 15

        for item in items {
            let view = item.view
            addArrangedSubview(view)
        }
    }
}
