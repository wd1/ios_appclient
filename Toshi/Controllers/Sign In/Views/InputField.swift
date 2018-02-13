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

class InputField: UIView {

    static let height: CGFloat = 45

    enum FieldType {
        case username
        case password
    }

    var type: FieldType!

    lazy var textField: UITextField = {
        let view = UITextField(withAutoLayout: true)
        view.font = Theme.preferredRegularMedium()
        view.adjustsFontForContentSizeCategory = true
        view.textColor = Theme.darkTextColor
        view.delegate = self

        return view
    }()

    lazy var titleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.numberOfLines = 0
        view.isUserInteractionEnabled = false
        view.font = Theme.preferredRegularMedium()
        view.adjustsFontForContentSizeCategory = true
        switch self.type! {
        case .username:
            view.text = Localized("input_field_username_placeholder")
        case .password:
            view.text = Localized("input_field_password_placeholder")
        }
        view.textColor = Theme.greyTextColor
        view.textAlignment = .left

        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        return view
    }()

    lazy var topSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    lazy var shortBottomSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    lazy var bottomSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    private lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .light)
    }()

    convenience init(type: FieldType) {
        self.init(withAutoLayout: true)
        self.type = type
        backgroundColor = .white

        addSubview(topSeparatorView)
        addSubview(shortBottomSeparatorView)
        addSubview(bottomSeparatorView)
        addSubview(titleLabel)
        addSubview(textField)

        NSLayoutConstraint.activate([
            self.topSeparatorView.topAnchor.constraint(equalTo: self.topAnchor),
            self.topSeparatorView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.topSeparatorView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.topSeparatorView.heightAnchor.constraint(equalToConstant: .lineHeight),

            self.shortBottomSeparatorView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            self.shortBottomSeparatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.shortBottomSeparatorView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.shortBottomSeparatorView.heightAnchor.constraint(equalToConstant: .lineHeight),

            self.bottomSeparatorView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.bottomSeparatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.bottomSeparatorView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.bottomSeparatorView.heightAnchor.constraint(equalToConstant: .lineHeight),

            self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            self.titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            self.textField.topAnchor.constraint(equalTo: self.topAnchor),
            self.textField.leftAnchor.constraint(equalTo: self.titleLabel.rightAnchor, constant: 20),
            self.textField.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.textField.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])

        if self.type == .username {
            bottomSeparatorView.isHidden = true
            self.textField.autocapitalizationType = .none
        } else {
            topSeparatorView.isHidden = true
            shortBottomSeparatorView.isHidden = true
        }

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
    }

    @objc func tap(_: UITapGestureRecognizer) {
        textField.becomeFirstResponder()
    }
}

extension InputField: UITextFieldDelegate {

    func textFieldDidBeginEditing(_: UITextField) {
        feedbackGenerator.impactOccurred()
    }
}
