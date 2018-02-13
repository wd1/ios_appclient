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

import SweetUIKit
import UIKit
import TinyConstraints

final class DappViewController: DisappearingNavBarViewController {
    
    private let dapp: Dapp
    
    // MARK: Views
    
    private lazy var avatarImageView = AvatarImageView()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.preferredDisplayName()
        label.textAlignment = .center
        
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var urlLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.lightGreyTextColor

        return label
    }()
    
    private lazy var enterButton: ActionButton = {
        let button = ActionButton(margin: .defaultMargin)
        button.title = Localized("dapp_button_enter")
        button.addTarget(self,
                         action: #selector(didTapEnterButton(_:)),
                         for: .touchUpInside)
        
        return button
    }()
    
    // MARK: Overridden Superclass Properties

    override var backgroundTriggerView: UIView {
        return avatarImageView
    }

    override var titleTriggerView: UIView {
        return titleLabel
    }
    
    // MARK: - Initialization
    
    required init(with dapp: Dapp) {
        self.dapp = dapp
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = Theme.viewBackgroundColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure(for: dapp)
    }
    
    // MARK: - View setup

    override func addScrollableContent(to contentView: UIView) {
        let spacer = addTopSpacer(to: contentView)
        setupPrimaryStackView(in: contentView, below: spacer)
    }
    
    private func setupPrimaryStackView(in containerView: UIView, below viewToPinToBottomOf: UIView) {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .vertical
        
        let margin = CGFloat.defaultMargin
        
        containerView.addSubview(stackView)
        stackView.topToBottom(of: viewToPinToBottomOf)
        stackView.leftToSuperview(offset: margin)
        stackView.rightToSuperview(offset: margin)
        stackView.bottomToSuperview()
        
        stackView.addWithCenterConstraint(view: avatarImageView)
        avatarImageView.height(.defaultAvatarHeight)
        avatarImageView.width(.defaultAvatarHeight)
        stackView.addSpacing(margin, after: avatarImageView)

        stackView.addWithDefaultConstraints(view: titleLabel)
        stackView.addSpacing(.giantInterItemSpacing, after: titleLabel)
        
        stackView.addWithDefaultConstraints(view: descriptionLabel)
        stackView.addSpacing(.mediumInterItemSpacing, after: descriptionLabel)
        
        stackView.addWithDefaultConstraints(view: urlLabel)
        stackView.addSpacing(.largeInterItemSpacing, after: urlLabel)
        
        stackView.addWithDefaultConstraints(view: enterButton, margin: margin)
        enterButton.heightConstraint.constant = .defaultButtonHeight
        
        stackView.addSpacerView(with: .largeInterItemSpacing)
    }
    
    // MARK: - Configuration
    
    private func configure(for dapp: Dapp) {
        navBar.setTitle(dapp.name)
        titleLabel.text = dapp.name
        descriptionLabel.text = dapp.description
        urlLabel.text = dapp.url.absoluteString
        
        AvatarManager.shared.avatar(for: dapp.avatarUrlString, completion: { [weak self] image, _ in
            self?.avatarImageView.image = image
        })
    }
    
    // MARK: - Action Targets
    
    @objc private func didTapEnterButton(_ sender: UIButton) {
        let sofaWebController = SOFAWebController()
        sofaWebController.load(url: dapp.url)
        
        navigationController?.pushViewController(sofaWebController, animated: true)
        preferLargeTitleIfPossible(false)
    }
}
