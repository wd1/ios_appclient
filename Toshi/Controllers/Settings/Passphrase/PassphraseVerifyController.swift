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

class PassphraseVerifyController: UIViewController {

    private var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    private let navigationBarCompensation: CGFloat = 64

    lazy var textLabel = TextLabel(Localized("passphrase_verify_text"))

    private lazy var shuffledPassphraseView: PassphraseView = {
        let view = PassphraseView(with: Cereal().mnemonic.words, for: .shuffled)
        view.addDelegate = self

        return view
    }()

    private lazy var verifyPassphraseView: PassphraseView = {
        let view = PassphraseView(with: Cereal().mnemonic.words, for: .verification)
        view.removeDelegate = self
        view.verificationDelegate = self
        view.backgroundColor = Theme.passphraseVerificationContainerColor

        return view
    }()

    var passPhraseViewHeight: CGFloat = 147.0

    required init?(coder _: NSCoder) {
        fatalError("")
    }

    init() {
        super.init(nibName: nil, bundle: nil)

        title = Localized("passphrase_verify_navigation_title")
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
    }

    func addSubviewsAndConstraints() {
        let margin: CGFloat = 20

        let contentView = UIView()
        view.addSubview(contentView)

        contentView.edges(to: view)
        contentView.width(to: view)

        contentView.addSubview(textLabel)
        contentView.addSubview(verifyPassphraseView)
        contentView.addSubview(shuffledPassphraseView)

        textLabel.top(to: contentView, offset: 13)
        textLabel.left(to: contentView, offset: margin)
        textLabel.right(to: contentView, offset: -margin)

        verifyPassphraseView.topToBottom(of: textLabel, offset: margin)
        verifyPassphraseView.left(to: contentView, offset: margin)
        verifyPassphraseView.right(to: contentView, offset: -margin)
        verifyPassphraseView.height(passPhraseViewHeight)

        shuffledPassphraseView.topToBottom(of: verifyPassphraseView, offset: margin)
        shuffledPassphraseView.left(to: contentView, offset: margin)
        shuffledPassphraseView.right(to: contentView, offset: -margin)

        // Anchored the bottom of PassPhraseView to the bottomContainer, since the height is ambiguous otherwise
        if let bottomAnchor = shuffledPassphraseView.containers.last?.bottomAnchor {
            shuffledPassphraseView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 10).isActive = true
        }

        shuffledPassphraseView.bottom(to: contentView, offset: -margin)
    }
}

extension PassphraseVerifyController: AddDelegate {

    func add(_ wordView: PassphraseWordView) {
        guard let word = wordView.word else { return }

        verifyPassphraseView.add(word)
        wordView.isEnabled = false
    }
}

extension PassphraseVerifyController: RemoveDelegate {

    func remove(_ wordView: PassphraseWordView) {
        guard let word = wordView.word else { return }

        verifyPassphraseView.remove(word)
        shuffledPassphraseView.reset(word)
    }
}

extension PassphraseVerifyController: VerificationDelegate {

    func verify(_ phrase: Phrase) -> VerificationStatus {
        assert(Cereal().mnemonic.words.count <= 12, "Too large")

        let originalPhrase = Cereal().mnemonic.words

        guard originalPhrase.count == phrase.count else {
            return .tooShort
        }

        if originalPhrase == phrase.map { word in word.text } {
            DispatchQueue.main.asyncAfter(seconds: 0.5) {
                guard let rootViewController = self.navigationController?.viewControllers.first else { return }
                
                if rootViewController is SettingsController {
                    _ = self.navigationController?.popToRootViewController(animated: true)
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }

            return .correct
        }

        return .incorrect
    }
}
