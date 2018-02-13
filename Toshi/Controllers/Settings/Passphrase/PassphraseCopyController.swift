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

class PassphraseCopyController: UIViewController {

    private var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    lazy var textLabel: UILabel = {
        let view = TextLabel(Localized("passphrase_copy_text"))

        return view
    }()

    private lazy var actionButton: ActionButton = {
        let view = ActionButton(margin: 30)
        view.title = Localized("passphrase_copy_action")
        view.addTarget(self, action: #selector(proceed(_:)), for: .touchUpInside)

        return view
    }()

    private lazy var passphraseView = PassphraseView(with: Cereal().mnemonic.words, for: .original)

    private lazy var copyButton: ConfirmationButton = {
        let view = ConfirmationButton(withAutoLayout: true)
        view.title = Localized("passphrase_copy_confirm_title")
        view.confirmation = Localized("passphrase_copy_confirm_copied")
        view.addTarget(self, action: #selector(copyToClipBoard(_:)), for: .touchUpInside)

        return view
    }()

    private var passPhraseViewHeightConstraint: NSLayoutConstraint?

    init() {
        super.init(nibName: nil, bundle: nil)

        title = Localized("passphrase_copy_navigation_title")
        hidesBottomBarWhenPushed = true
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIScrollView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Theme.lightGrayBackgroundColor
        addSubviewsAndConstraints()
    }

    private func addSubviewsAndConstraints() {
        let margin: CGFloat = 20

        let contentView = UIView()
        view.addSubview(contentView)

        contentView.edges(to: view)
        contentView.width(to: view)
        contentView.height(to: layoutGuide(), relation: .equalOrGreater)

        contentView.addSubview(textLabel)
        contentView.addSubview(passphraseView)
        contentView.addSubview(copyButton)
        contentView.addSubview(actionButton)

        textLabel.top(to: contentView, offset: 13)
        textLabel.left(to: contentView, offset: margin)
        textLabel.right(to: contentView, offset: -margin)

        passphraseView.topToBottom(of: textLabel, offset: margin)
        passphraseView.left(to: contentView, offset: margin)
        passphraseView.right(to: contentView, offset: -margin)

        // Anchored the bottom of PassPhraseView to the bottomContainer, since the height is ambiguous otherwise
        if let bottomAnchor = passphraseView.containers.last?.bottomAnchor {
            passphraseView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 10).isActive = true
        }

        copyButton.topToBottom(of: passphraseView)
        copyButton.height(35)
        copyButton.left(to: contentView, offset: margin)
        copyButton.right(to: contentView, offset: -margin)

        actionButton.height(50)
        actionButton.left(to: contentView, offset: margin)
        actionButton.right(to: contentView, offset: -margin)
        actionButton.topToBottom(of: copyButton, offset: 40, relation: .equalOrGreater)
        actionButton.bottom(to: contentView, offset: -50)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(true)
    }

    @objc func proceed(_: ActionButton) {
        let controller = PassphraseVerifyController()
        navigationController?.pushViewController(controller, animated: true)
        controller.passPhraseViewHeight = passphraseView.frame.height
    }

    @objc func copyToClipBoard(_ button: ConfirmationButton) {
        copyStringToClipboard(Cereal().mnemonic.words.joined(separator: " "),
                              thenUpdate: button)
    }
}

extension PassphraseCopyController: ClipboardCopying { /* mix-in */ }
