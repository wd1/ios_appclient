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
import SafariServices

let logoTopSpace: CGFloat = 100.0
let logoSize: CGFloat = 54.0

let titleLabelToSpace: CGFloat = 27.0

final class SplashViewController: UIViewController {

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(withAutoLayout: true)
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.image = UIImage(named: "launch-screen")

        return imageView
    }()

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(withAutoLayout: true)
        imageView.contentMode = .center
        imageView.image = UIImage(named: "logo")

        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.regular(size: 43.0)
        label.textAlignment = .center
        label.textColor = Theme.viewBackgroundColor
        label.numberOfLines = 0
        label.text = Localized("welcome_title")

        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.preferredRegular()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Theme.viewBackgroundColor.withAlphaComponent(0.6)
        label.numberOfLines = 0

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .center

        let attrString = NSMutableAttributedString(string: Localized("welcome_subtitle"))
        attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrString.length))

        label.attributedText = attrString

        return label
    }()

    private lazy var newAccountButton: UIButton = {
        let button = UIButton(withAutoLayout: true)
        button.setTitle(Localized("create_account_button_title"), for: .normal)
        button.setTitleColor(Theme.viewBackgroundColor, for: .normal)
        button.addTarget(self, action: #selector(newAccountPressed(_:)), for: .touchUpInside)
        button.titleLabel?.font = Theme.preferredTitle3()
        button.titleLabel?.adjustsFontForContentSizeCategory = true

        return button
    }()

    private lazy var signinButton: UIButton = {
        let button = UIButton(withAutoLayout: true)
        button.isUserInteractionEnabled = true
        button.setTitle(Localized("sign_in_button_title"), for: .normal)
        button.setTitleColor(Theme.viewBackgroundColor, for: .normal)
        button.addTarget(self, action: #selector(signinPressed(_:)), for: .touchUpInside)
        button.titleLabel?.font = Theme.preferredRegularMedium()
        button.titleLabel?.adjustsFontForContentSizeCategory = true

        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        decorateView()
    }

    private func decorateView() {
        let margin: CGFloat = 15.0

        view.addSubview(backgroundImageView)
        backgroundImageView.fillSuperview()

        backgroundImageView.addSubview(logoImageView)
        logoImageView.topAnchor.constraint(equalTo: backgroundImageView.topAnchor, constant: logoTopSpace).isActive = true
        logoImageView.centerXAnchor.constraint(equalTo: backgroundImageView.centerXAnchor).isActive = true
        logoImageView.set(height: logoSize)
        logoImageView.set(width: logoSize)

        backgroundImageView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 24.0).isActive = true
        titleLabel.left(to: view, offset: margin)
        titleLabel.right(to: view, offset: -margin)

        backgroundImageView.addSubview(subtitleLabel)
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: margin).isActive = true
        subtitleLabel.left(to: view, offset: margin)
        subtitleLabel.right(to: view, offset: -margin)

        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        backgroundImageView.addSubview(newAccountButton)
        newAccountButton.left(to: view, offset: margin)
        newAccountButton.height(44.0)
        newAccountButton.right(to: view, offset: -margin)
        newAccountButton.topToBottom(of: subtitleLabel, offset: margin, relation: .equalOrGreater)

        backgroundImageView.addSubview(signinButton)
        signinButton.topToBottom(of: newAccountButton, offset: margin)
        signinButton.left(to: view, offset: margin)
        signinButton.right(to: view, offset: -margin)
        signinButton.height(44.0)
        signinButton.bottomAnchor.constraint(equalTo: backgroundImageView.bottomAnchor, constant: -40.0).isActive = true
    }

    @objc private func signinPressed(_: UIButton) {
        let controller = SignInViewController()
        controller.delegate = self
        Navigator.push(controller, from: self)
    }

    @objc private func newAccountPressed(_: UIButton) {
        showAcceptTermsAlert()
    }
    
    private func showAcceptTermsAlert() {
        
        let alert = UIAlertController(title: Localized("accept_terms_title"), message: Localized("accept_terms_text"), preferredStyle: .alert)
        
        let read = UIAlertAction(title: Localized("accept_terms_action_read"), style: .default) { [weak self] _ in
            guard let url = URL(string: "http://www.toshi.org/terms-of-service/") else { return }
            let controller = SFSafariViewController(url: url, entersReaderIfAvailable: true)
            controller.delegate = self
            controller.preferredControlTintColor = Theme.tintColor
            self?.present(controller, animated: true, completion: nil)
        }
        
        let cancel = UIAlertAction(title: Localized("cancel_action_title"), style: .default) { _ in
            alert.dismiss(animated: true, completion: nil)
        }
        
        let agree = UIAlertAction(title: Localized("accept_terms_action_agree"), style: .cancel) { [weak self] _ in
            Navigator.tabbarController?.setupControllers()
            SessionManager.shared.createNewUser()
            self?.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(read)
        alert.addAction(cancel)
        alert.addAction(agree)
        
        present(alert, animated: true, completion: nil)
    }
}

extension SplashViewController: SignInViewControllerDelegate {

    func didRequireNewAccountCreation(_ controller: SignInViewController) {
        navigationController?.popToViewController(self, animated: true)
            self.showAcceptTermsAlert()
    }
}

extension SplashViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        showAcceptTermsAlert()
    }
}
