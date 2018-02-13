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

protocol PaymentConfirmationViewControllerDelegate: class {
    func paymentConfirmationViewControllerFinished(on controller: PaymentConfirmationViewController, parameters: [String: Any], transactionHash: String?, error: ToshiError?)
    func paymentConfirmationViewControllerDidCancel(_ controller: PaymentConfirmationViewController)
}

enum RecipientType {
    case
    user(info: UserInfo?),
    dapp(info: DappInfo)
}

enum PresentationMethod {
    case
    fullScreen,
    modalBottomSheet
}

final class PaymentConfirmationViewController: UIViewController {

    weak var delegate: PaymentConfirmationViewControllerDelegate?

    private let paymentManager: PaymentManager

    private var recipientType: RecipientType
    private let shouldSendSignedTransaction: Bool

    private let parameters: [String: Any]

    // MARK: - Lazy views

    private lazy var avatarImageView: AvatarImageView = {
        let imageView = AvatarImageView()
        imageView.image = UIImage(named: "avatar-placeholder")

        return imageView
    }()

    var originalUnsignedTransaction: String? {
        return paymentManager.transaction
    }

    private lazy var recipientLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredRegular()
        view.textColor = Theme.lightGreyTextColor
        view.adjustsFontForContentSizeCategory = true

        switch recipientType {
        case .user:
            view.textAlignment = .center
            view.text = Localized("confirmation_recipient")
        case .dapp:
            view.textAlignment = .left
            view.text = Localized("confirmation_dapp")
        }

        return view
    }()

    // MARK: User

    private lazy var userNameLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredDisplayName()
        view.textAlignment = .center
        view.adjustsFontForContentSizeCategory = true
        view.textColor = Theme.darkTextColor

        switch recipientType {
        case .user(let userInfo):
            view.text = userInfo?.name
        default:
            break // don't set.
        }

        return view
    }()

    // MARK: Dapp

    private lazy var dappInfoLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 2
        view.font = Theme.preferredSemibold()
        view.adjustsFontForContentSizeCategory = true
        view.textColor = Theme.darkTextColor

        return view
    }()

    private lazy var dappURLLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.preferredFootnote()
        view.textColor = Theme.lightGreyTextColor

        return view
    }()

    // MARK: Payment sheet style title

    private var hasLaidOutBefore = false
    private var bottomOfReceiptConstraint: NSLayoutConstraint?

    var backgroundView: UIView? {
        didSet {
            guard let background = backgroundView else { return }

            let alpha = UIView()
            alpha.backgroundColor = .black
            alpha.alpha = 0.5

            background.addSubview(alpha)
            alpha.edgesToSuperview()

            view.insertSubview(background, at: 0)
        }
    }

    var presentationMethod: PresentationMethod = .fullScreen {
        didSet {
            switch presentationMethod {
            case .fullScreen:
                // Not much to do here
                break
            case .modalBottomSheet:
                self.modalTransitionStyle = .crossDissolve
            }
        }
    }

    private lazy var paymentSheetTitleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.preferredSemibold()
        view.textAlignment = .center
        view.adjustsFontForContentSizeCategory = true
        view.text = title

        return view
    }()

    private lazy var paymentSheetCancelButton: UIButton = {
        let view = UIButton()
        view.titleLabel?.adjustsFontForContentSizeCategory = true
        view.setTitleColor(Theme.tintColor, for: .normal)
        view.addTarget(self, action: #selector(cancelItemTapped), for: .touchUpInside)
        view.setTitle(Localized("cancel_action_title"), for: .normal)

        return view
    }()

    // MARK: Payment section

    private lazy var fetchingNetworkFeesLabel: UILabel = {
        let view = UILabel()
        view.backgroundColor = Theme.viewBackgroundColor
        view.numberOfLines = 0
        view.font = Theme.preferredRegular()
        view.textColor = Theme.lightGreyTextColor
        view.textAlignment = .center
        view.adjustsFontForContentSizeCategory = true

        view.text = Localized("confirmation_fetching_estimated_network_fees")

        return view
    }()

    private lazy var receiptView: ReceiptView = {
        let view = ReceiptView()

        view.alpha = 0

        return view
    }()

    private lazy var payButton: ActionButton = {
        let button = ActionButton(margin: 15)
        button.title = Localized("confirmation_pay")
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)

        return button
    }()

    private lazy var balanceLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredFootnote()
        view.textColor = Theme.lightGreyTextColor
        view.textAlignment = .center
        view.adjustsFontForContentSizeCategory = true

        view.text = Localized("confirmation_fetching_balance")

        return view
    }()

    // MARK: - Initialization

    init(parameters: [String: Any], recipientType: RecipientType, shouldSendSignedTransaction: Bool = true) {
        paymentManager = PaymentManager(parameters: parameters)
        self.recipientType = recipientType
        self.shouldSendSignedTransaction = shouldSendSignedTransaction
        self.parameters = parameters

        super.init(nibName: nil, bundle: nil)

        guard let address = parameters[PaymentParameters.to] as? String, EthereumAddress.validate(address) else {
            assertionFailure("Invalid payment address on Payment confirmation")
            return
        }

        fetchUserWithCurrentPaymentAddressIfNeeded(address)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localized("confirmation_title")
        addSubviewsAndConstraints()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelItemTapped))

        displayRecipientDetails()
        view.backgroundColor = Theme.viewBackgroundColor

        payButton.showSpinner()

        paymentManager.fetchPaymentInfo { [weak self] paymentInfo in
            DispatchQueue.main.async {
                self?.payButton.hideSpinner()
                self?.receiptView.setPaymentInfo(paymentInfo)

                self?.receiptView.alpha = 1
                UIView.animate(withDuration: 0.2) {
                    self?.fetchingNetworkFeesLabel.alpha = 0
                }

                self?.setBalance(paymentInfo.balanceString, isSufficient: paymentInfo.sufficientBalance)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        switch presentationMethod {
        case .fullScreen:
            // do nothing
            return
        case .modalBottomSheet:
            guard !hasLaidOutBefore, bottomOfReceiptConstraint != nil else { return }

            hasLaidOutBefore = true

            // First, shove the receipt offscreen non-animated so the user can't see it.
            setReceiptShowing(false, animated: false)

            // Then, start animating it back in.
            setReceiptShowing(true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        switch presentationMethod {
        case .fullScreen:
            // Do nothing
            return
        case .modalBottomSheet:
            setReceiptShowing(false, animated: animated)
        }
    }

    // MARK: - View Setup

    private func addSubviewsAndConstraints() {
        let receiptPayBalanceView = setupReceiptPayBalance(in: view)

        switch recipientType {
        case .user:
            addProfileStackViewLayout(to: view, above: receiptPayBalanceView)
        case .dapp:
            addDappStackViewLayout(to: view, above: receiptPayBalanceView)
            // we don't have the possibility to show the dapp avator right now, so we hide it.
            avatarImageView.isHidden = true
        }
    }

    private func setupReceiptPayBalance(in parentView: UIView) -> UIView {
        let receiptPayBalanceStackView = UIStackView()
        receiptPayBalanceStackView.axis = .vertical
        receiptPayBalanceStackView.alignment = .center

        receiptPayBalanceStackView.addBackground(with: Theme.viewBackgroundColor, margin: .defaultMargin)

        parentView.addSubview(receiptPayBalanceStackView)

        bottomOfReceiptConstraint = receiptPayBalanceStackView.bottom(to: layoutGuide(), offset: -.defaultMargin)
        receiptPayBalanceStackView.leftToSuperview(offset: .defaultMargin)
        receiptPayBalanceStackView.rightToSuperview(offset: .defaultMargin)

        receiptPayBalanceStackView.addWithDefaultConstraints(view: receiptView)

        receiptPayBalanceStackView.addSpacing(.largeInterItemSpacing, after: receiptView)

        // Don't add the network fees view as an arranged subview - pin it to the receipt view
        // so it floats in the same place where the pay balance view will appear
        receiptPayBalanceStackView.addSubview(fetchingNetworkFeesLabel)
        fetchingNetworkFeesLabel.edges(to: receiptView)

        receiptPayBalanceStackView.addWithDefaultConstraints(view: payButton)
        receiptPayBalanceStackView.addSpacing(.largeInterItemSpacing, after: payButton)

        receiptPayBalanceStackView.addWithDefaultConstraints(view: balanceLabel)

        return receiptPayBalanceStackView
    }

    private func addProfileStackViewLayout(to parentView: UIView, above viewToPinToTopOf: UIView) {
        let profileDetailsStackView = UIStackView()
        profileDetailsStackView.axis = .vertical
        profileDetailsStackView.alignment = .center

        profileDetailsStackView.addBackground(with: Theme.viewBackgroundColor)

        // Setup layout guides to allow the profile details stack view to float in between the top of
        // the parent view and the top of the view to pin it above.
        let profileDetailsTopLayoutGuide = UILayoutGuide()
        parentView.addLayoutGuide(profileDetailsTopLayoutGuide)
        profileDetailsTopLayoutGuide.height(.mediumInterItemSpacing, relation: .equalOrGreater)
        profileDetailsTopLayoutGuide.top(to: layoutGuide())
        profileDetailsTopLayoutGuide.left(to: parentView)
        profileDetailsTopLayoutGuide.right(to: parentView)

        let profileDetailsBottomLayoutGuide = UILayoutGuide()
        parentView.addLayoutGuide(profileDetailsBottomLayoutGuide)
        profileDetailsBottomLayoutGuide.height(to: profileDetailsTopLayoutGuide)
        profileDetailsBottomLayoutGuide.left(to: parentView)
        profileDetailsBottomLayoutGuide.right(to: parentView)
        profileDetailsBottomLayoutGuide.bottomToTop(of: viewToPinToTopOf)

        parentView.addSubview(profileDetailsStackView)

        profileDetailsStackView.topToBottom(of: profileDetailsTopLayoutGuide)
        profileDetailsStackView.leftToSuperview(offset: .defaultMargin)
        profileDetailsStackView.rightToSuperview(offset: .defaultMargin)
        profileDetailsStackView.bottomToTop(of: profileDetailsBottomLayoutGuide)

        profileDetailsStackView.addWithCenterConstraint(view: avatarImageView)
        avatarImageView.height(.defaultAvatarHeight)
        avatarImageView.width(.defaultAvatarHeight)
        profileDetailsStackView.addSpacing(.defaultMargin, after: avatarImageView)

        profileDetailsStackView.addWithDefaultConstraints(view: recipientLabel)
        profileDetailsStackView.addWithDefaultConstraints(view: userNameLabel)
    }

    private func addDappStackViewLayout(to parentView: UIView, above viewToPinToTopOf: UIView) {
        let dappStackView = UIStackView()
        dappStackView.axis = .vertical
        dappStackView.alignment = .center

        parentView.addSubview(dappStackView)

        dappStackView.addBackground(with: Theme.viewBackgroundColor)

        dappStackView.leftToSuperview()
        dappStackView.rightToSuperview()
        dappStackView.bottomToTop(of: viewToPinToTopOf)

        dappStackView.addStandardBorder()
        addTitleCancelView(to: dappStackView)

        let afterTitleBorder = dappStackView.addStandardBorder()
        dappStackView.addSpacing(.largeInterItemSpacing, after: afterTitleBorder)

        dappStackView.addWithDefaultConstraints(view: recipientLabel, margin: .defaultMargin)
        dappStackView.addSpacing(12, after: recipientLabel)

        let textStackView = UIStackView()
        textStackView.axis = .vertical
        textStackView.spacing = 4

        textStackView.addArrangedSubview(dappInfoLabel)
        textStackView.addArrangedSubview(dappURLLabel)

        let websiteInfoStackView = UIStackView()
        websiteInfoStackView.axis = .horizontal
        websiteInfoStackView.alignment = .top

        websiteInfoStackView.addArrangedSubview(textStackView)
        websiteInfoStackView.addArrangedSubview(avatarImageView)

        let dappAvatarHeight: CGFloat = 48
        avatarImageView.height(dappAvatarHeight)
        avatarImageView.width(dappAvatarHeight)

        dappStackView.addWithDefaultConstraints(view: websiteInfoStackView, margin: .defaultMargin)
        dappStackView.addSpacing(.largeInterItemSpacing, after: websiteInfoStackView)

        dappStackView.addStandardBorder()

        dappStackView.addSpacerView(with: .largeInterItemSpacing)
    }

    private func addTitleCancelView(to stackView: UIStackView) {
        let titleView = UIView()
        titleView.backgroundColor = .clear

        titleView.addSubview(paymentSheetCancelButton)
        paymentSheetCancelButton.centerYToSuperview()
        paymentSheetCancelButton.leftToSuperview(offset: .defaultMargin)

        titleView.addSubview(paymentSheetTitleLabel)
        paymentSheetTitleLabel.centerYToSuperview()
        paymentSheetTitleLabel.centerXToSuperview()
        paymentSheetTitleLabel.leftToRight(of: paymentSheetCancelButton, offset: .mediumInterItemSpacing, relation: .equalOrGreater)

        stackView.addWithDefaultConstraints(view: titleView)
        titleView.height(.defaultBarHeight)
    }

    // MARK: - Animation

    private func setReceiptShowing(_ showing: Bool, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let bottomConstraint = bottomOfReceiptConstraint else { /* nothing to adjust yet */ return }

        let targetConstraintConstant: CGFloat = showing ? -.largeInterItemSpacing : view.frame.height

        guard bottomOfReceiptConstraint?.constant != targetConstraintConstant else { /* already where we want it to be */ return }

        // Execute any pending layout operations before the one we want to animate
        view.layoutIfNeeded()

        let options: UIViewAnimationOptions = showing ? [.curveEaseOut] : [.curveEaseIn]
        let duration = animated ? 0.4 : 0
        bottomConstraint.constant = targetConstraintConstant

        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            completion?()
        })
    }
    // MARK: - Configuration for display

    private func displayRecipientDetails() {
        fetchAvatarIfNeeded()

        switch recipientType {
        case .user(let userInfo):
            userNameLabel.text = userInfo?.name
        case .dapp(let dappInfo):
            dappInfoLabel.text = dappInfo.headerText
            guard let urlComponents = URLComponents(url: dappInfo.dappURL, resolvingAgainstBaseURL: false) else { return }
            dappURLLabel.text = urlComponents.host
        }
    }

    private func fetchUserWithCurrentPaymentAddressIfNeeded(_ address: String) {
        switch recipientType {
        case .dapp:
            // No info needs to be fetched for something that is not a user.
            return
        case .user:
            IDAPIClient.shared.findUserWithPaymentAddress(address) { [weak self] user, _ in
                self?.recipientType = .user(info: user?.userInfo)
                self?.displayRecipientDetails()
            }
        }
    }

    private func fetchAvatarIfNeeded() {
        let path: String?
        switch recipientType {
        case .user(let userInfo):
            path = userInfo?.avatarPath
        case .dapp(let dappInfo):
            path = dappInfo.imagePath
        }

        guard let avatarPath = path else { return }

        AvatarManager.shared.avatar(for: avatarPath, completion: { [weak self] image, _ in
            self?.avatarImageView.image = image
        })
    }

    private func setBalance(_ balanceString: String, isSufficient: Bool) {
        if isSufficient {
            UIView.animate(withDuration: 0.2) {
                self.balanceLabel.textColor = Theme.lightGreyTextColor
                self.balanceLabel.text = String(format: Localized("confirmation_your_balance"), balanceString)

                self.payButton.isEnabled = true
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.balanceLabel.textColor = Theme.errorColor
                self.balanceLabel.text = String(format: Localized("confirmation_insufficient_balance"), balanceString)

                self.payButton.isEnabled = false
            }
        }
    }

    // MARK: - Action Targets

    @objc func cancelItemTapped() {
        switch presentationMethod {
        case .fullScreen:
            actuallyDismiss()
        case .modalBottomSheet:
            self.setReceiptShowing(false) {
                self.actuallyDismiss()
           }
        }

        delegate?.paymentConfirmationViewControllerDidCancel(self)
    }

    private func actuallyDismiss() {
        self.dismiss(animated: true, completion: nil)
    }

    private func sendPayment() {
        payButton.showSpinner()

        paymentManager.sendPayment { [weak self] error, transactionHash in
            guard let weakSelf = self else { return }

            weakSelf.payButton.hideSpinner()

            guard error == nil else {
                let alert = UIAlertController(title: Localized("transaction_error_message"), message: (error?.description ?? ToshiError.genericError.description), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Localized("alert-ok-action-title"), style: .default, handler: { _ in
                    weakSelf.delegate?.paymentConfirmationViewControllerFinished(on: weakSelf, parameters: weakSelf.paymentManager.parameters, transactionHash: transactionHash, error: error)
                }))

                Navigator.presentModally(alert)

                return
            }

            weakSelf.delegate?.paymentConfirmationViewControllerFinished(on: weakSelf, parameters: weakSelf.paymentManager.parameters, transactionHash: transactionHash, error: error)
        }
    }

    @objc func didTapPayButton() {

        if shouldSendSignedTransaction {
            sendPayment()
        } else {
            self.delegate?.paymentConfirmationViewControllerFinished(on: self, parameters: self.paymentManager.parameters, transactionHash: "", error: nil)
        }
    }
}
