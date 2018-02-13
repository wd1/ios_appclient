import Foundation
import UIKit
import TinyConstraints

class BalanceController: UIViewController {
    private var paymentRouter: PaymentRouter?
    
    enum BalanceItem: Int {
        case balance,
             send,
             deposit
    }

    var balance: NSDecimalNumber? {
        didSet {
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        }
    }

    private var isAccountSecured: Bool {
        return TokenUser.current?.verified ?? false
    }

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.backgroundColor = nil
        view.dataSource = self
        view.delegate = self
        view.separatorStyle = .singleLine

        view.register(UITableViewCell.self)
        view.registerNib(InputCell.self)

        return view
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)

        return refreshControl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if !isAccountSecured {
            showSecurityAlert()
        }

        view.backgroundColor = Theme.lightGrayBackgroundColor

        title = Localized("balance_navigation_title")

        view.addSubview(tableView)
        tableView.edges(to: view)
        tableView.refreshControl = refreshControl

        NotificationCenter.default.addObserver(self, selector: #selector(handleBalanceUpdate(notification:)), name: .ethereumBalanceUpdateNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchAndUpdateBalance()

        preferLargeTitleIfPossible(false)
    }

    @objc private func refresh(_ refreshControl: UIRefreshControl) {
        fetchAndUpdateBalance { _ in
            refreshControl.endRefreshing()
        }
    }

    private func showSecurityAlert() {
        let alert = UIAlertController(title: Localized("settings_deposit_error_title"), message: Localized("settings_deposit_error_message"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized("cancel_action_title"), style: .default, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: Localized("settings_deposit_error_action_backup"), style: .default, handler: { _ in
            let passphraseEnableController = PassphraseEnableController()
            let navigationController = UINavigationController(rootViewController: passphraseEnableController)
            Navigator.presentModally(navigationController)
        }))

        Navigator.presentModally(alert)
    }

    @objc private func handleBalanceUpdate(notification: Notification) {
        guard notification.name == .ethereumBalanceUpdateNotification, let balance = notification.object as? NSDecimalNumber else { return }
        self.balance = balance
    }

    private func fetchAndUpdateBalance(completion: ((_ success: Bool) -> Void)? = nil) {

        EthereumAPIClient.shared.getBalance(cachedBalanceCompletion: { [weak self] cachedBalance, error in
            self?.balance = cachedBalance
        }, fetchedBalanceCompletion: { [weak self] fetchedBalance, error in
            if let error = error {
                Navigator.presentModally(UIAlertController.errorAlert(error as NSError))
                completion?(false)
            } else {
                self?.balance = fetchedBalance
                completion?(true)
            }
        })
    }
}

extension BalanceController: UITableViewDelegate {

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = BalanceItem(rawValue: indexPath.row) else { return }

        switch item {
        case .send:
            let paymentRouter = PaymentRouter()
            paymentRouter.present()

            self.paymentRouter = paymentRouter
        case .deposit:
            guard let current = TokenUser.current else { return }
            let controller = DepositMoneyController(for: current.displayUsername, name: current.name)
            self.navigationController?.pushViewController(controller, animated: true)
        default:
            break
        }
    }
}

extension BalanceController: UITableViewDataSource {

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()

        guard let item = BalanceItem(rawValue: indexPath.row) else { return cell }

        switch item {
        case .balance:
            cell = tableView.dequeue(InputCell.self, for: indexPath)
            if let balance = balance, let cell = cell as? InputCell {
                let ethereumValueString = EthereumConverter.ethereumValueString(forWei: balance)
                let fiatValueString = EthereumConverter.fiatValueStringWithCode(forWei: balance, exchangeRate: ExchangeRateClient.exchangeRate)

                cell.titleLabel.text = fiatValueString
                cell.textField.text = ethereumValueString
                cell.textField.textAlignment = .right
                cell.textField.isUserInteractionEnabled = false
                cell.switchControl.isHidden = true

                cell.titleWidthConstraint?.isActive = false
                cell.titleLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
            }
        case .send:
            cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
            cell.textLabel?.text = Localized("balance_action_send")
            cell.textLabel?.textColor = Theme.tintColor
            cell.textLabel?.font = Theme.preferredRegular()
        case .deposit:
            cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
            cell.textLabel?.text = Localized("balance_action_deposit")
            cell.textLabel?.textColor = Theme.tintColor
            cell.textLabel?.font = Theme.preferredRegular()
        }

        cell.selectionStyle = .none
        return cell
    }
}
