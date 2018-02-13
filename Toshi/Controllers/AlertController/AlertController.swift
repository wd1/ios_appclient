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
import UIKit
import SweetUIKit

typealias ActionBlock = ((Action) -> Void)

struct Action {

    private(set) var title: String
    private(set) var titleColor: UIColor
    private(set) var icon: UIImage?
    private(set) var block: ActionBlock

    init(title: String, titleColor: UIColor = UIColor.lightGray, icon: UIImage? = nil, block: @escaping ActionBlock) {
        self.title = title
        self.titleColor = titleColor
        self.icon = icon
        self.block = block
    }
}

class AlertController: ModalPresentable {
    static let contentWidth: CGFloat = 310

    var customContentView: UIView? {
        didSet {
            arrangeCustomView()
        }
    }

    private lazy var actionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.backgroundColor = Theme.greyTextColor
        stackView.spacing = 1.0

        return stackView
    }()

    lazy var reviewContainer: UIView = {
        let view = UIView(withAutoLayout: true)

        return view
    }()

    var actions = [Action]() {
        didSet {
            self.setupActionsButtons()
        }
    }

    func arrangeCustomView() {
        if let customContentView = self.customContentView {
            reviewContainer.addSubview(customContentView)
            self.customContentView?.fillSuperview()
        }

        reviewContainer.setNeedsLayout()
        reviewContainer.layoutIfNeeded()

        visualEffectView.setNeedsLayout()
        visualEffectView.layoutIfNeeded()

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.6, alpha: 0.7)

        view.addSubview(background)
        view.addSubview(visualEffectView)

        visualEffectView.backgroundColor = Theme.lightGreyTextColor

        visualEffectView.contentView.addSubview(actionsStackView)
        visualEffectView.contentView.addSubview(reviewContainer)

        reviewContainer.topAnchor.constraint(equalTo: visualEffectView.topAnchor).isActive = true
        reviewContainer.leftAnchor.constraint(equalTo: visualEffectView.leftAnchor).isActive = true
        reviewContainer.rightAnchor.constraint(equalTo: visualEffectView.rightAnchor).isActive = true

        actionsStackView.topAnchor.constraint(equalTo: reviewContainer.bottomAnchor, constant: 1.0).isActive = true
        actionsStackView.leftAnchor.constraint(equalTo: visualEffectView.leftAnchor).isActive = true
        actionsStackView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor).isActive = true
        actionsStackView.rightAnchor.constraint(equalTo: visualEffectView.rightAnchor).isActive = true

        background.fillSuperview()

        visualEffectView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        visualEffectView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        visualEffectView.widthAnchor.constraint(equalToConstant: AlertController.contentWidth).isActive = true

        background.addGestureRecognizer(tapGesture)
    }

    lazy var tapGesture: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        gestureRecognizer.cancelsTouchesInView = false

        return gestureRecognizer
    }()

    @objc func tap(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .recognized {
            dismiss(animated: true)
        }
    }

    private lazy var contentViewVerticalCenter: NSLayoutConstraint = {
        self.visualEffectView.centerYAnchor.constraint(equalTo: self.background.centerYAnchor)
    }()

    private func setupActionsButtons() {
        for action in actions {
            let button = self.button(for: action)
            actionsStackView.addArrangedSubview(button)
        }
    }

    private func button(for action: Action) -> UIButton {
        let button = UIButton(type: .custom)
        button.set(height: 44.0)
        button.backgroundColor = Theme.viewBackgroundColor
        button.setTitle(action.title, for: .normal)
        button.setTitleColor(action.titleColor, for: .normal)
        button.setImage(action.icon, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 10.0)

        button.addTarget(self, action: #selector(actionButtonPressed(_:)), for: .touchUpInside)

        return button
    }

    @objc private func actionButtonPressed(_ button: UIButton) {
        guard let buttonIndex = self.actionsStackView.arrangedSubviews.index(of: button) else { return }
        guard actions.count - 1 >= buttonIndex else { return }

        let action: Action = actions[buttonIndex]
        action.block(action)
    }
}
