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
import CoreImage
import TinyConstraints

final class ProfileViewController: DisappearingNavBarViewController {
    
    var profile: TokenUser {
        didSet {
            configureForCurrentProfile()
        }
    }

    var paymentRouter: PaymentRouter?

    private let isReadOnlyMode: Bool
    
    private var isBotProfile: Bool {
        return profile.isApp
    }
    
    private var isForCurrentUserProfile: Bool {
        return profile.isCurrentUser
    }
    
    private var shouldShowMoreButton: Bool {
        return !isForCurrentUserProfile
    }
    
    private var isProfileEditable: Bool {
        return (!isReadOnlyMode && isForCurrentUserProfile)
    }
    
    private var shouldShowRateButton: Bool {
        return !isForCurrentUserProfile
    }

    private lazy var activityView: UIActivityIndicatorView = {
        self.defaultActivityIndicator()
    }()

    private var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    private var messageSender: MessageSender? {
        return SessionManager.shared.messageSender
    }
    
    private let belowTableViewStyleLabelSpacing: CGFloat = 8
    
    private lazy var avatarImageView = AvatarImageView()
    
    private lazy var nameLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredDisplayName()
        view.textAlignment = .center
        view.adjustsFontForContentSizeCategory = true
        
        return view
    }()
    
    private lazy var usernameLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.textAlignment = .center
        view.font = Theme.preferredRegularMedium()
        view.adjustsFontForContentSizeCategory = true
        view.textColor = Theme.greyTextColor
        
        return view
    }()
    
    private lazy var messageUserButton: ActionButton = {
        let button = ActionButton(margin: .defaultMargin)
        button.setButtonStyle(.primary)
        button.title = Localized("profile_message_button_title")
        button.addTarget(self, action: #selector(didTapMessageButton), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var payButton: ActionButton = {
        let button = ActionButton(margin: .defaultMargin)
        button.setButtonStyle(.secondary)
        button.title = Localized("profile_pay_button_title")
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var editProfileButton: ActionButton = {
        let view = ActionButton(margin: .defaultMargin)
        view.setButtonStyle(.secondary)
        view.title = Localized("profile_edit_button_title")
        view.addTarget(self, action: #selector(didTapEditProfileButton), for: .touchUpInside)
        view.clipsToBounds = true
        
        return view
    }()
    
    private lazy var aboutContentLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.preferredRegular()
        view.adjustsFontForContentSizeCategory = true
        view.numberOfLines = 0
        
        return view
    }()
    
    private lazy var locationContentLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.preferredRegularMedium()
        view.adjustsFontForContentSizeCategory = true
        view.textColor = Theme.lightGreyTextColor
        view.numberOfLines = 0
        
        return view
    }()
    
    private lazy var aboutStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .vertical
        
        return stackView
    }()
    
    private lazy var reputationTitle: UILabel = {
        let view = UILabel()
        view.font = Theme.preferredFootnote()
        view.textColor = Theme.sectionTitleColor
        view.text = Localized("profile_reputation_section_header")
        view.adjustsFontForContentSizeCategory = true
        
        return view
    }()
    
    private lazy var reputationView = ReputationView()
    
    private lazy var rateThisUserButton: UIButton = {
        let view = UIButton()
        view.setTitleColor(Theme.tintColor, for: .normal)
        view.setTitleColor(Theme.greyTextColor, for: .highlighted)
        view.titleLabel?.font = Theme.preferredRegular()
        view.titleLabel?.adjustsFontForContentSizeCategory = true
        view.clipsToBounds = true
        
        view.addTarget(self, action: #selector(didTapRateUserButton), for: .touchUpInside)
        
        return view
    }()

    // MARK: Superclass property overrides

    override var backgroundTriggerView: UIView {
        return avatarImageView
    }

    override var titleTriggerView: UIView {
        return nameLabel
    }

    override var disappearingEnabled: Bool {
        return !isProfileEditable
    }

    override var topSpacerHeight: CGFloat {
        if isProfileEditable {
            return navBarHeight + .giantInterItemSpacing
        } else {
            return navBarHeight
        }
    }

    // MARK: - Initialization

    init(profile: TokenUser, readOnlyMode: Bool = true) {
        self.profile = profile
        self.isReadOnlyMode = readOnlyMode

        super.init(nibName: nil, bundle: nil)

        title = Localized("profile_title")
    }

    required init?(coder _: NSCoder) {
        fatalError("The method `init?(coder)` is not implemented for this class.")
    }
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Theme.viewBackgroundColor

        if shouldShowMoreButton {
            navBar.setRightButtonImage(#imageLiteral(resourceName: "more_centered"), accessibilityLabel: Localized("accessibility_more"))
        }
        
        if isProfileEditable {
            navBar.showTitleAndBackground()
        }

        setupActivityIndicator()

        configureForCurrentProfile()
        updateReputation()
    }

    // MARK: - View Setup

    override func addScrollableContent(to contentView: UIView) {
        let topSpacer = addTopSpacer(to: contentView)

        let profileContainer = addProfileDetailsSection(to: contentView, below: topSpacer)

        let titleContainer = addReputationTitle(to: contentView, below: profileContainer)

        let reputationContainer = addReputationSection(to: contentView, below: titleContainer)

        addGrayBackgroundBottom(to: contentView, below: reputationContainer)
    }

    // MARK: Profile
    
    private func addProfileDetailsSection(to container: UIView, below viewToPinToBottomOf: UIView) -> UIView {
        let profileDetailsStackView = UIStackView()
        profileDetailsStackView.addBackground(with: Theme.viewBackgroundColor)
        profileDetailsStackView.axis = .vertical
        profileDetailsStackView.alignment = .center
        
        container.addSubview(profileDetailsStackView)
        profileDetailsStackView.leftToSuperview()
        profileDetailsStackView.rightToSuperview()
        profileDetailsStackView.topToBottom(of: viewToPinToBottomOf)
        
        let margin = CGFloat.defaultMargin
        
        profileDetailsStackView.addWithCenterConstraint(view: avatarImageView)
        avatarImageView.height(.defaultAvatarHeight)
        avatarImageView.width(.defaultAvatarHeight)
        profileDetailsStackView.addSpacing(margin, after: avatarImageView)
        
        profileDetailsStackView.addWithDefaultConstraints(view: nameLabel, margin: margin)
        
        if isBotProfile {
            setupRestOfBotProfileSection(in: profileDetailsStackView, after: nameLabel, margin: margin)
        } else {
            profileDetailsStackView.addSpacing(.smallInterItemSpacing, after: nameLabel)
            profileDetailsStackView.addWithDefaultConstraints(view: usernameLabel)
            
            if isProfileEditable {
                setupRestOfEditableProfileSection(in: profileDetailsStackView, after: usernameLabel, margin: margin)
            } else {
                setupRestOfStandardProfileSection(in: profileDetailsStackView, after: usernameLabel, margin: margin)
            }
        }
        
        return profileDetailsStackView
    }
    
    private func setupRestOfBotProfileSection(in stackView: UIStackView, after lastAddedView: UIView, margin: CGFloat) {
        stackView.addSpacing(.giantInterItemSpacing, after: lastAddedView)
        
        stackView.addWithDefaultConstraints(view: aboutContentLabel, margin: .defaultMargin)
        stackView.addSpacing(.largeInterItemSpacing, after: aboutContentLabel)
        
        stackView.addWithDefaultConstraints(view: messageUserButton, margin: .defaultMargin)
        stackView.addSpacing(.largeInterItemSpacing, after: messageUserButton)
        
        let bottomBorder = BorderView()
        stackView.addWithDefaultConstraints(view: bottomBorder)
        bottomBorder.addHeightConstraint()
    }
    
    private func setupRestOfEditableProfileSection(in stackView: UIStackView, after lastAddedView: UIView, margin: CGFloat) {
        stackView.addSpacing(.giantInterItemSpacing, after: lastAddedView)
        
        setupProfileAboutSection(in: stackView, withTopBorder: false, margin: margin)
        
        stackView.addWithDefaultConstraints(view: editProfileButton, margin: .defaultMargin)
        stackView.addSpacing(.largeInterItemSpacing, after: editProfileButton)
        
        let bottomBorder = BorderView()
        stackView.addWithDefaultConstraints(view: bottomBorder)
        bottomBorder.addHeightConstraint()
    }
    
    private func setupRestOfStandardProfileSection(in stackView: UIStackView, after lastAddedView: UIView, margin: CGFloat) {
        if isForCurrentUserProfile {
            // You can't message or pay yourself.
            stackView.addSpacing(.largeInterItemSpacing, after: lastAddedView)
        } else {
            // You *can* message or pay other users.
            stackView.addSpacing(.giantInterItemSpacing, after: lastAddedView)

            stackView.addWithDefaultConstraints(view: messageUserButton, margin: margin)
            stackView.addSpacing(.mediumInterItemSpacing, after: messageUserButton)
            
            stackView.addWithDefaultConstraints(view: payButton, margin: margin)
            stackView.addSpacing(.largeInterItemSpacing, after: payButton)
        }
        
        setupProfileAboutSection(in: stackView, withTopBorder: true, margin: margin)
        
        let bottomBorder = BorderView()
        stackView.addWithDefaultConstraints(view: bottomBorder)
        bottomBorder.addHeightConstraint()
    }
    
    private func setupProfileAboutSection(in stackView: UIStackView, withTopBorder: Bool, margin: CGFloat) {
        stackView.addWithDefaultConstraints(view: aboutStackView)
        
        if withTopBorder {
            let topBorder = BorderView()
            aboutStackView.addWithDefaultConstraints(view: topBorder)
            topBorder.addHeightConstraint()
            aboutStackView.addSpacing(.largeInterItemSpacing, after: topBorder)
        }
        
        aboutStackView.addWithDefaultConstraints(view: aboutContentLabel, margin: margin)
        aboutStackView.addSpacing(.mediumInterItemSpacing, after: aboutContentLabel)
        
        aboutStackView.addWithDefaultConstraints(view: locationContentLabel, margin: margin)

        // This needs a spacer on both iOS 10 and 11 since adding custom spacing doesn't do anything if there's not another view below it.
        let belowLocationSpacerView = UIView()
        belowLocationSpacerView.backgroundColor = .clear
        aboutStackView.addWithDefaultConstraints(view: belowLocationSpacerView)
        belowLocationSpacerView.height(.largeInterItemSpacing)
    }

    // MARK: Reputation
    
    private func addReputationTitle(to container: UIView, below viewToPinToBottomOf: UIView) -> UIView {
        let titleContainer = UIView()
        titleContainer.backgroundColor = Theme.lightGrayBackgroundColor

        container.addSubview(titleContainer)
        titleContainer.leftToSuperview()
        titleContainer.rightToSuperview()
        titleContainer.topToBottom(of: viewToPinToBottomOf)

        titleContainer.addSubview(reputationTitle)

        reputationTitle.leftToSuperview(offset: .defaultMargin)
        reputationTitle.rightToSuperview(offset: -.defaultMargin)
        reputationTitle.topToSuperview(offset: .giantInterItemSpacing)
        reputationTitle.bottomToSuperview(offset: -belowTableViewStyleLabelSpacing)

        return titleContainer
    }
    
    private func addReputationSection(to container: UIView, below viewToPinToBottomOf: UIView) -> UIView {
        let reputationStackView = UIStackView()
        reputationStackView.addBackground(with: Theme.viewBackgroundColor)
        reputationStackView.axis = .vertical
        reputationStackView.alignment = .center
        
        container.addSubview(reputationStackView)
        
        reputationStackView.leftToSuperview()
        reputationStackView.rightToSuperview()
        reputationStackView.topToBottom(of: viewToPinToBottomOf)

        let topBorder = BorderView()
        reputationStackView.addWithDefaultConstraints(view: topBorder)
        topBorder.addHeightConstraint()
        reputationStackView.addSpacing(.largeInterItemSpacing, after: topBorder)
        
        addReputationView(to: reputationStackView)
        
        if shouldShowRateButton {
            reputationStackView.addWithDefaultConstraints(view: rateThisUserButton)
            rateThisUserButton.height(.defaultButtonHeight)

            if isBotProfile {
                rateThisUserButton.setTitle(Localized("profile_rate_user"), for: .normal)
            } else {
                rateThisUserButton.setTitle(Localized("profile_rate_user"), for: .normal)
            }
        } else {
            reputationStackView.addSpacing(.largeInterItemSpacing, after: reputationView.superview!)
        }
        
        let bottomBorder = BorderView()
        reputationStackView.addWithDefaultConstraints(view: bottomBorder)
        bottomBorder.addHeightConstraint()

        return reputationStackView
    }
    
    private func addReputationView(to stackView: UIStackView) {
        let container = UIView()
        container.addSubview(reputationView)
        reputationView.topToSuperview()
        reputationView.widthToSuperview(multiplier: 0.66)
        reputationView.centerXToSuperview(offset: -6) //eyeballed
        reputationView.bottomToSuperview()
        
        stackView.addWithDefaultConstraints(view: container)
        stackView.addSpacing(.defaultMargin, after: container)
    }

    private func addGrayBackgroundBottom(to container: UIView, below viewToPinToBottomOf: UIView) {
        let backgroundBottom = UIView()
        backgroundBottom.backgroundColor = Theme.lightGrayBackgroundColor

        container.addSubview(backgroundBottom)

        backgroundBottom.topToBottom(of: viewToPinToBottomOf)
        backgroundBottom.leftToSuperview()
        backgroundBottom.rightToSuperview()

        // Prevent the user from discovering the background of the superview is not gray if they scroll beyond
        // the desired bottom spacing.
        let backgroundHeight = UIScreen.main.bounds.height
        backgroundBottom.height(backgroundHeight)
        backgroundBottom.bottomToSuperview(offset: (backgroundHeight - .largeInterItemSpacing))
    }

    // MARK: - Configuration
    
    private func configureForCurrentProfile() {
        // Set nils for empty strings to make the views collapse in the stack view
        nameLabel.text = profile.name.isEmpty ? nil : profile.name
        aboutContentLabel.text = profile.about.isEmpty ? nil : profile.about
        locationContentLabel.text = profile.location.isEmpty ? nil : profile.location
        usernameLabel.text = profile.displayUsername
        
        if isProfileEditable {
            navBar.setTitle(Localized("profile_me_title"))
        } else {
            navBar.setTitle(profile.nameOrDisplayName)
        }

        if aboutStackView.superview != nil {
            // This is all in a section and should be hidden at once
            let shouldShowAboutSection = (aboutContentLabel.hasContent || locationContentLabel.hasContent)
            aboutStackView.isHidden = !shouldShowAboutSection
        } else {
            aboutContentLabel.isHidden = !aboutContentLabel.hasContent
        }
        
        AvatarManager.shared.avatar(for: profile.avatarPath) { [weak self] image, _ in
            if image != nil {
                self?.avatarImageView.image = image
            }
        }
    }
    
    // MARK: - Action Targets
    
    // MARK: Button targets
    
    @objc private func didTapMessageButton() {
        let thread = ChatInteractor.getOrCreateThread(for: profile.address)
        thread.isPendingAccept = false
        thread.save()
        
        DispatchQueue.main.async {
            (self.tabBarController as? TabBarController)?.displayMessage(forAddress: self.profile.address)
            
            if let navController = self.navigationController as? BrowseNavigationController {
                _ = navController.popToRootViewController(animated: false)
            }
        }
    }
    
    @objc private func didTapPayButton() {
        let paymentRouter = PaymentRouter(parameters: [PaymentParameters.to: profile.paymentAddress])
        paymentRouter.delegate = self
        paymentRouter.userInfo = profile.userInfo
        paymentRouter.present()

        self.paymentRouter = paymentRouter

    }
    
    @objc private func didTapEditProfileButton() {
        let editController = ProfileEditController()
        navigationController?.pushViewController(editController, animated: true)
    }
    
    @objc private func didTapRateUserButton() {
        presentUserRatingPrompt(profile: profile)
    }
    
    @objc private func didSelectMoreButton() {
        presentMoreActionSheet()
    }
    
    // MARK: Action sheet targets
    
    private func didSelectBlockedState(_ shouldBeBlocked: Bool) {
        if shouldBeBlocked {
            presentBlockConfirmationAlert()
        } else {
            unblockUser()
        }
    }
    
    private func didSelectReportUser() {
        self.idAPIClient.reportUser(address: profile.address) { [weak self] success, error in
            self?.presentReportUserFeedbackAlert(success, message: error?.description)
        }
    }
    
    private func didSelectFavoriteState(_ shouldBeFavorited: Bool) {
        if shouldBeFavorited {
            favoriteUser()
        } else {
            unfavoriteUser()
        }
    }

    // MARK: - Alerts
    
    private func presentUserRatingPrompt(profile: TokenUser) {
        let rateUserController = RateUserController(user: profile)
        rateUserController.delegate = self

        Navigator.presentModally(rateUserController)
    }
    
    private func presentMoreActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let currentFavoriteState = isCurrentUserFavorite()
        let favoriteTitle = isCurrentUserFavorite() ? Localized("profile_unfavorite_action") : Localized("profile_favorite_action")
        let favoriteAction = UIAlertAction(title: favoriteTitle, style: .default) { _ in
            self.didSelectFavoriteState(!currentFavoriteState)
        }
        actionSheet.addAction(favoriteAction)
        
        let currentBlockState = profile.isBlocked
        let blockTitle = currentBlockState ? Localized("unblock_action_title") : Localized("block_action_title")
        let blockAction = UIAlertAction(title: blockTitle, style: .destructive) { [weak self] _ in
            self?.didSelectBlockedState(!currentBlockState)
        }
        actionSheet.addAction(blockAction)
        
        let reportAction = UIAlertAction(title: Localized("report_action_title"), style: .destructive) { [weak self] _ in
            self?.didSelectReportUser()
        }
        actionSheet.addAction(reportAction)
        
        actionSheet.addAction(UIAlertAction(title: Localized("cancel_action_title"), style: .cancel))
        
        Navigator.presentModally(actionSheet)
    }
    
    private func presentBlockConfirmationAlert() {
        let alert = UIAlertController(title: Localized("block_alert_title"), message: Localized("block_alert_message"), preferredStyle: .alert)
        
        let blockAction = UIAlertAction(title: Localized("block_action_title"), style: .default) { [weak self] _ in
            self?.blockUser()
        }
        alert.addAction(blockAction)
        
        alert.addAction(UIAlertAction(title: Localized("cancel_action_title"), style: .cancel))
        
        Navigator.presentModally(alert)
    }

    private func presentReportUserFeedbackAlert(_ success: Bool, message: String?) {
        guard success else {
            let alert = UIAlertController.dismissableAlert(title: Localized("error_title"), message: message)
            Navigator.presentModally(alert)

            return
        }

        let alert = UIAlertController.dismissableAlert(title: Localized("report_feedback_alert_title"), message: Localized("report_feedback_alert_message"))
        Navigator.presentModally(alert)
    }
    
    private func presentSubmitRatingErrorAlert(error: ToshiError?) {
        let alert = UIAlertController(title: Localized("error_title"), message: error?.description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized("alert-ok-action-title"), style: .default))
        
        Navigator.presentModally(alert)
    }
    
    // MARK: - Other helpers

    private func updateReputation() {
        RatingsClient.shared.scores(for: profile.address) { [weak self] ratingScore in
            self?.reputationView.setScore(ratingScore)
        }
    }
    
    // MARK: - User helpers
    
    private func blockUser() {
        OWSBlockingManager.shared().addBlockedPhoneNumber(profile.address)
        
        let alert = UIAlertController.dismissableAlert(title: Localized("block_feedback_alert_title"), message: Localized("block_feedback_alert_message"))
        Navigator.presentModally(alert)
    }
    
    private func unblockUser() {
        OWSBlockingManager.shared().removeBlockedPhoneNumber(profile.address)
        
        let alert = UIAlertController.dismissableAlert(title: Localized("unblock_user_title"), message: Localized("unblock_user_message"))
        Navigator.presentModally(alert)
    }

    private func favoriteUser() {
        Yap.sharedInstance.insert(object: profile.json, for: profile.address, in: TokenUser.favoritesCollectionKey)
        SoundPlayer.playSound(type: .addedProfile)
    }
    
    private func unfavoriteUser() {
        Yap.sharedInstance.removeObject(for: profile.address, in: TokenUser.favoritesCollectionKey)
    }
    
    private func isCurrentUserFavorite() -> Bool {
        return Yap.sharedInstance.containsObject(for: profile.address, in: TokenUser.favoritesCollectionKey)
    }

    // MARK: - Background Nav Bar Delegate Overrides

    override func didTapRightButton(in navBar: DisappearingBackgroundNavBar) {
        guard shouldShowMoreButton else {
            assertionFailure("Probably shouldn't be able to tap a button that shouldn't be showing")

            return
        }

        didSelectMoreButton()
    }
}

// MARK: - Activity Indicating

extension ProfileViewController: ActivityIndicating {
    var activityIndicator: UIActivityIndicatorView {
        return activityView
    }
}

// MARK: - Rate User Controller Delegate

extension ProfileViewController: RateUserControllerDelegate {
    func didRate(_ user: TokenUser, rating: Int, review: String) {
        dismiss(animated: true) {
            RatingsClient.shared.submit(userId: user.address, rating: rating, review: review) { [weak self] success, error in
                guard success == true else {
                    self?.presentSubmitRatingErrorAlert(error: error)
                    
                    return
                }

                self?.updateReputation()
            }
        }
    }
}

// MARK: - Payment Controller Delegate

extension ProfileViewController: PaymentRouterDelegate {

    func paymentRouterDidSucceedPayment(_ paymentRouter: PaymentRouter, parameters: [String: Any], transactionHash: String?, unsignedTransaction: String?, error: ToshiError?) {
        Navigator.topViewController?.dismiss(animated: true, completion: nil)
    }
}
