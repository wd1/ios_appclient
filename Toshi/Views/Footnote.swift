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
import SweetUIKit

class Footnote: UIView {

    private lazy var icon: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.image = #imageLiteral(resourceName: "info")

        return view
    }()

    private lazy var textLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.numberOfLines = 0
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    convenience init(text: String) {
        self.init(withAutoLayout: true)

        addSubview(icon)
        addSubview(textLabel)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.paragraphSpacing = 5

        let attributes: [NSAttributedStringKey: Any] = [
            .font: Theme.preferredFootnote(),
            .foregroundColor: Theme.greyTextColor,
            .paragraphStyle: paragraphStyle
        ]

        textLabel.attributedText = NSMutableAttributedString(string: text, attributes: attributes)

        let imageSize = icon.image?.size ?? .zero

        NSLayoutConstraint.activate([
            self.icon.topAnchor.constraint(equalTo: self.topAnchor, constant: 1),
            self.icon.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.icon.widthAnchor.constraint(equalToConstant: imageSize.width),
            self.icon.heightAnchor.constraint(equalToConstant: imageSize.height),

            self.textLabel.topAnchor.constraint(equalTo: self.topAnchor),
            self.textLabel.leftAnchor.constraint(equalTo: self.icon.rightAnchor, constant: 6),
            self.textLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.textLabel.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
    }
}
