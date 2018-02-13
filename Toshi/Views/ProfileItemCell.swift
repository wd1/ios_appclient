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
import Formulaic

/// Display profile items for editing inside ProfileEditController
class ProfileItemCell: UITableViewCell {

    var formItem: FormItem? {
        didSet {
            itemLabel.text = formItem?.title
            itemTextField.text = formItem?.value as? String
        }
    }

    lazy var itemLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.darkTextColor
        view.font = Theme.semibold(size: 15)

        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)

        return view
    }()

    lazy var itemTextField: UITextField = {
        let view = UITextField(withAutoLayout: true)
        view.textColor = Theme.darkTextColor
        view.font = Theme.preferredRegularSmall()
        view.adjustsFontForContentSizeCategory = true
        view.textAlignment = .right

        return view
    }()

    lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(itemLabel)
        contentView.addSubview(itemTextField)
        contentView.addSubview(separatorView)

        let margin: CGFloat = 22.0

        itemLabel.set(height: 44)
        itemLabel.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        itemLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin).isActive = true
        itemLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        itemTextField.set(height: 44)
        itemTextField.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        itemTextField.leftAnchor.constraint(equalTo: itemLabel.rightAnchor, constant: margin).isActive = true
        itemTextField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        itemTextField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin).isActive = true

        separatorView.set(height: .lineHeight)
        separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        separatorView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin).isActive = true
        separatorView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true

        NotificationCenter.default.addObserver(self, selector: #selector(ProfileItemCell.textFieldDidChange), name: .UITextFieldTextDidChange, object: itemTextField)
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        formItem = nil
    }
}

extension ProfileItemCell: UITextFieldDelegate {

    @objc func textFieldDidChange() {
        self.formItem?.updateValue(to: self.itemTextField.text, userInitiated: true)
    }
}
