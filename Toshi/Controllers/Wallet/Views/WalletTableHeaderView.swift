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
import TinyConstraints

protocol WalletTableViewHeaderDelegate: class {
    func copyAddress(_ address: String, from headerView: WalletTableHeaderView)
    func openAddress(_ address: String, from headerView: WalletTableHeaderView)
}

// MARK: - View

final class WalletTableHeaderView: UIView {

    private let walletAddress: String
    private weak var delegate: WalletTableViewHeaderDelegate?

    private lazy var qrCodeImageView: UIImageView = {
        let imageView = UIImageView()
        let qrCodeImageSize: CGFloat = 28

        imageView.width(qrCodeImageSize)
        imageView.height(qrCodeImageSize)

        imageView.image = #imageLiteral(resourceName: "qr")

        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.lightTextColor
        label.text = Localized("wallet_address_title")
        label.font = Theme.preferredSemibold()

        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.lightTextColor.withAlphaComponent(0.8)
        label.numberOfLines = 0
        label.text = Localized("wallet_address_subtitle")
        label.font = Theme.preferredFootnote()

        return label
    }()

    private lazy var walletAddressLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.preferredRegularMonospaced()
        label.lineBreakMode = .byTruncatingMiddle
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()

    private lazy var copyButton: UIButton = {
        let button = UIButton(type: .custom)

        button.layer.borderColor = Theme.tintColor.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 2
        button.contentEdgeInsets = UIEdgeInsets(top: .smallInterItemSpacing, left: .mediumInterItemSpacing, bottom: .smallInterItemSpacing, right: .mediumInterItemSpacing)
        button.titleLabel?.font = Theme.preferredFootnote()
        button.setTitle(Localized("copy_action_title"), for: .normal)
        button.setTitleColor(Theme.tintColor, for: .normal)
        button.addTarget(self, action: #selector(copyAddressTapped), for: .touchUpInside)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        return button
    }()

    // MARK: - Initialization

    /// Designated initializer
    ///
    /// - Parameters:
    ///   - frame: The frame to pass through to super.
    ///   - address: The address to display
    ///   - delegate: The delegate to notify of changes.
    init(frame: CGRect, address: String, delegate: WalletTableViewHeaderDelegate) {
        walletAddress = address
        self.delegate = delegate
        super.init(frame: frame)

        backgroundColor = Theme.tintColor

        setupMainStackView()

        walletAddressLabel.text = walletAddress
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Setup

    private func setupMainStackView() {
        let stackView = UIStackView()

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        addSubview(stackView)

        stackView.edgesToSuperview(insets: UIEdgeInsets(top: .largeInterItemSpacing,
                                                        left: .spacingx3,
                                                        bottom: .largeInterItemSpacing,
                                                        right: -.spacingx3))

        stackView.addWithDefaultConstraints(view: titleLabel)
        stackView.addSpacing(.smallInterItemSpacing, after: titleLabel)
        stackView.addWithDefaultConstraints(view: subtitleLabel)
        stackView.addSpacing(.spacingx3, after: subtitleLabel)
        addCardView(to: stackView)
    }

    private func addCardView(to stackView: UIStackView) {
        let cardView = UIView(withAutoLayout: true)
        cardView.layer.cornerRadius = 10.0

        cardView.addShadow(xOffset: 0, yOffset: 2, radius: 4)
        cardView.backgroundColor = Theme.viewBackgroundColor

        let tapRecognizer = UITapGestureRecognizer(target: self,
                                                   action: #selector(openAddressTapped))
        cardView.addGestureRecognizer(tapRecognizer)

        stackView.addWithDefaultConstraints(view: cardView)

        let innerStackView = UIStackView()
        innerStackView.axis = .horizontal
        innerStackView.alignment = .center
        innerStackView.spacing = .spacingx3

        cardView.addSubview(innerStackView)
        innerStackView.topToSuperview(offset: .largeInterItemSpacing)
        innerStackView.bottomToSuperview(offset: -.largeInterItemSpacing)
        innerStackView.leftToSuperview(offset: .largeInterItemSpacing)
        innerStackView.rightToSuperview(offset: .largeInterItemSpacing)

        innerStackView.addArrangedSubview(qrCodeImageView)
        innerStackView.addArrangedSubview(walletAddressLabel)
        innerStackView.addArrangedSubview(copyButton)
    }

    // MARK: - Action Targets

    @objc private func copyAddressTapped() {
        delegate?.copyAddress(walletAddress, from: self)
    }

    @objc private func openAddressTapped() {
        delegate?.openAddress(walletAddress, from: self)
    }

}
