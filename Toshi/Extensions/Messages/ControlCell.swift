// Copyright (c) 2017 Token Browser, Inc
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

protocol ControlCellDelegate: class {
    func didTapButton(for cell: ControlCell)
}

class SubcontrolCell: ControlCell {

    override var buttonInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: 15, bottom: 4, right: 15)
    }

    lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.separatorColor

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(separatorView)

        separatorView.set(height: 1)
        separatorView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        separatorView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        contentView.layer.cornerRadius = 0.0
        contentView.layer.borderColor = nil
        contentView.layer.borderWidth = 0.0

        button.setTitleColor(Theme.darkTextColor, for: .normal)
        button.setTitleColor(Theme.actionButtonTitleColor, for: .highlighted)
        button.setTitleColor(Theme.darkTextColor, for: .selected)
        button.titleLabel?.font = Theme.preferredRegularSmall()
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentHorizontalAlignment = .left

        button.fillSuperview(with: buttonInsets)
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }
}

class ControlCell: UICollectionViewCell {
    weak var delegate: ControlCellDelegate?

    var buttonInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }

    var buttonItem: SofaMessage.Button? {
        didSet {
            let title = buttonItem?.label
            self.button.setTitle(title, for: .normal)
            self.button.titleLabel?.lineBreakMode = .byTruncatingTail
        }
    }

    lazy var button: UIButton = {
        let view = UIButton(withAutoLayout: true)
        view.setTitleColor(Theme.actionButtonTitleColor, for: .normal)
        view.setTitleColor(Theme.greyTextColor, for: .highlighted)
        view.setTitleColor(Theme.greyTextColor, for: .selected)
        view.titleLabel?.font = Theme.medium(size: 15)

        view.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = Theme.viewBackgroundColor
        contentView.layer.cornerRadius = 8
        contentView.layer.borderColor = Theme.borderColor.cgColor
        contentView.layer.borderWidth = Theme.borderHeight

        contentView.addSubview(button)

        button.fillSuperview(with: buttonInsets)
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    @objc func didTapButton() {
        let wasSelected = button.isSelected
        delegate?.didTapButton(for: self)
        button.isSelected = !wasSelected
    }
}
