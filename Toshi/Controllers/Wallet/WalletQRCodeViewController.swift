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

final class WalletQRCodeViewController: UIViewController {

    private lazy var qrCodeImageView: UIImageView = {
        let imageView = UIImageView()

        let qrCodeSize: CGFloat = 160
        imageView.width(qrCodeSize)
        imageView.height(qrCodeSize)

        return imageView
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()

        button.setImage(#imageLiteral(resourceName: "close_icon"), for: .normal)
        button.width(.defaultButtonHeight)
        button.height(.defaultButtonHeight)

        button.accessibilityLabel = Localized("accessibility_close")
        button.addTarget(self,
                         action: #selector(closeButtonTapped),
                         for: .touchUpInside)

        return button
    }()

    private let buttonCornerRadius: CGFloat = 6

    private lazy var shareButton: ActionButton = {
        let button = ActionButton(margin: 0, cornerRadius: buttonCornerRadius)
        button.title = Localized("share_action_title")
        button.addTarget(self,
                         action: #selector(shareButtonTapped),
                         for: .touchUpInside)

        return button
    }()

    private lazy var copyButton: ActionButton = {
        let button = ActionButton(margin: 0, cornerRadius: buttonCornerRadius)
        button.setButtonStyle(.secondary)
        button.title = Localized("copy_action_title")
        button.addTarget(self,
                         action: #selector(copyButtonTapped),
                         for: .touchUpInside)

        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.darkTextColor
        label.font = Theme.preferredRegularMedium()
        label.text = Localized("wallet_address_title")
        
        return label
    }()

    private lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = Theme.preferredRegularMonospaced()
        label.textAlignment = .center

        return label
    }()

    private let address: String

    // MARK: - Initialization

    init(address: String) {
        self.address = address
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = Theme.viewBackgroundColor

        setupCloseButton()
        setupTitleLabel(yAlignedWith: closeButton)
        setupQRCodeImageView()
        setupAddressLabel(below: qrCodeImageView)
        setupButtons()

        addressLabel.text = address.toLines(count: 2)
        qrCodeImageView.image = QRCodeGenerator.qrCodeImage(for: .ethereumAddress(address: address))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Use the other initializer!")
    }

    // MARK: - View Setup

    private func setupCloseButton() {
        view.addSubview(closeButton)

        closeButton.top(to: layoutGuide())
        closeButton.leadingToSuperview()
    }

    private func setupTitleLabel(yAlignedWith viewToAlignToCenterYOf: UIView) {
        view.addSubview(titleLabel)

        titleLabel.centerY(to: viewToAlignToCenterYOf)
        titleLabel.centerXToSuperview()
    }

    private func setupQRCodeImageView() {
        view.addSubview(qrCodeImageView)

        qrCodeImageView.centerXToSuperview()
        qrCodeImageView.centerYToSuperview()
    }

    private func setupAddressLabel(below viewToPinToBottomOf: UIView) {
        view.addSubview(addressLabel)

        addressLabel.leadingToSuperview(offset: .largeInterItemSpacing)
        addressLabel.trailingToSuperview(offset: .largeInterItemSpacing)
        addressLabel.topToBottom(of: viewToPinToBottomOf, offset: .mediumInterItemSpacing)
    }

    private func setupButtons() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = .mediumInterItemSpacing

        view.addSubview(stackView)

        stackView.bottom(to: layoutGuide(), offset: -.largeInterItemSpacing)
        stackView.leadingToSuperview(offset: .largeInterItemSpacing)
        stackView.trailingToSuperview(offset: .largeInterItemSpacing)
        stackView.height(.defaultButtonHeight)

        stackView.addArrangedSubview(copyButton)
        stackView.addArrangedSubview(shareButton)
    }

    // MARK: - Action Targets

    @objc private func closeButtonTapped() {
        self.dismiss(animated: true)
    }

    @objc private func shareButtonTapped() {
        shareWithSystemSheet(item: address)
    }

    @objc private func copyButtonTapped() {
        copyToClipboardWithGenericAlert(address)
    }
}

// MARK: - Mix-in extensions

extension WalletQRCodeViewController: ClipboardCopying { /* mix-in */ }
extension WalletQRCodeViewController: SystemSharing { /* mix-in */ }
