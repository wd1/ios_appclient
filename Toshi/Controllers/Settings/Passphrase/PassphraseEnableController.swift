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

class PassphraseEnableController: UIViewController {

    private lazy var titleLabel: TextLabel = {
        let textLabel = TextLabel(Localized("passphrase_enable_title"))
        textLabel.font = Theme.preferredSemibold()
        textLabel.adjustsFontForContentSizeCategory = true

        return textLabel
    }()
    
    lazy var textLabel = TextLabel(Localized("passphrase_enable_text"))
    
    lazy var checkboxControl: CheckboxControl = {
        let text = Localized("passphrase_enable_checkbox")

        let view = CheckboxControl()
        view.title = text
        view.addTarget(self, action: #selector(checked(_:)), for: .touchUpInside)

        return view
    }()

    private lazy var actionButton: ActionButton = {
        let view = ActionButton(margin: 30)
        view.title = Localized("passphrase_enable_action")
        view.isEnabled = false
        view.addTarget(self, action: #selector(proceed(_:)), for: .touchUpInside)

        return view
    }()
    
    private var isPresentedModally: Bool {
        return navigationController?.presentingViewController != nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(nibName: nil, bundle: nil)

        title = Localized("passphrase_enable_navigation_title")
        hidesBottomBarWhenPushed = true
    }

    override func loadView() {
        let scrollView = UIScrollView()

        view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.lightGrayBackgroundColor

        addSubviewsAndConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(true)

        if isPresentedModally {
            let item = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismiss(_:)))
            navigationItem.setLeftBarButtonItems([item], animated: true)
        }
    }

    private func addSubviewsAndConstraints() {
        let margin: CGFloat = 20

        let contentView = UIView()
        view.addSubview(contentView)

        contentView.edges(to: view)
        contentView.width(to: view)
        contentView.height(to: layoutGuide(), relation: .equalOrGreater)

        contentView.addSubview(titleLabel)
        contentView.addSubview(textLabel)
        contentView.addSubview(checkboxControl)
        contentView.addSubview(actionButton)

        titleLabel.top(to: contentView, offset: 13)
        titleLabel.left(to: contentView, offset: margin)
        titleLabel.right(to: contentView, offset: -margin)

        textLabel.topToBottom(of: titleLabel, offset: 20)
        textLabel.left(to: view, offset: margin)
        textLabel.right(to: view, offset: -margin)

        checkboxControl.topToBottom(of: textLabel, offset: margin)
        checkboxControl.height(66, relation: .equalOrGreater)
        checkboxControl.left(to: view, offset: margin)
        checkboxControl.right(to: view, offset: -margin)

        actionButton.height(50)
        actionButton.left(to: contentView, offset: margin)
        actionButton.right(to: contentView, offset: -margin)
        actionButton.topToBottom(of: checkboxControl, offset: 2 * margin, relation: .equalOrGreater)
        actionButton.bottom(to: contentView, offset: -50)
    }

    @objc func dismiss(_ item: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @objc func checked(_ checkboxControl: CheckboxControl) {
        checkboxControl.checkbox.checked = !checkboxControl.checkbox.checked
        actionButton.isEnabled = checkboxControl.checkbox.checked
    }
    
    @objc func proceed(_: ActionButton) {
        let controller = PassphraseCopyController()
        navigationController?.pushViewController(controller, animated: true)
    }
}
