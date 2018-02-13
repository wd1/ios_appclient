import Foundation
import UIKit
import TinyConstraints

final class CurrencyPicker: UIViewController {

    private static let popularCurrenciesCodes = ["USD", "EUR", "CNY", "GBP", "CAD"]

    private var suggestedCurrencies: [Currency] = []
    private var otherCurrencies: [Currency] = []

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .grouped)

        view.backgroundColor = nil
        view.isOpaque = false
        view.delegate = self
        view.dataSource = self
        view.tableFooterView = UIView()
        view.register(UITableViewCell.self)
        view.layer.borderWidth = .lineHeight
        view.layer.borderColor = Theme.borderColor.cgColor

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localized("currency_picker_title")
        view.backgroundColor = Theme.lightGrayBackgroundColor
        addSubviewsAndConstraints()

        self.tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(false)

        ExchangeRateClient.getCurrencies { [weak self] results in
            guard let strongSelf = self else { return }

            let availableLocaleCurrencies = Locale.availableIdentifiers.flatMap { Locale(identifier: $0).currencyCode }

            strongSelf.otherCurrencies = results
                .filter { result in
                    availableLocaleCurrencies.contains(result.code) && !CurrencyPicker.popularCurrenciesCodes.contains(result.code)
                }
                .sorted { firstCurrency, secondCurrency -> Bool in
                    return  firstCurrency.code < secondCurrency.code
            }

            strongSelf.suggestedCurrencies = results
                .filter { result in
                    CurrencyPicker.popularCurrenciesCodes.contains(result.code)
                }.sorted { firstCurrency, secondCurrency -> Bool in
                    return  firstCurrency.code < secondCurrency.code
            }

            strongSelf.tableView.reloadData()
            strongSelf.tableView.scrollToRow(at: strongSelf.currentLocalCurrencyIndexPath, at: .middle, animated: false)
        }
    }

    func addSubviewsAndConstraints() {
        view.addSubview(tableView)
        tableView.edges(to: view)
    }

    private var currentLocalCurrencyIndexPath: IndexPath {
        
        guard let currentUser = TokenUser.current else {
            CrashlyticsLogger.log("No current user during session", attributes: [.occurred: "Currency picker"])
            fatalError("No current user on CurrencyListController")
        }
        
        let currentLocalCurrencyCode = currentUser.localCurrency

        if let suggestedCurrencyIndex = suggestedCurrencies.index(where: {$0.code == currentLocalCurrencyCode}) {
            return IndexPath(row: suggestedCurrencyIndex, section: 0)
        }

        let currentLocalCurrencyIndex = otherCurrencies.index(where: {$0.code == currentLocalCurrencyCode}) ?? 0
        return IndexPath(row: currentLocalCurrencyIndex, section: 1)
    }
}

extension CurrencyPicker: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let previousLocalCurrencyIndexPath = currentLocalCurrencyIndexPath

        let selectedCode = indexPath.section == 0 ? suggestedCurrencies[indexPath.row].code : otherCurrencies[indexPath.row].code
        TokenUser.current?.updateLocalCurrency(code: selectedCode)

        let indexPathsToReload = [previousLocalCurrencyIndexPath, indexPath]
        tableView.reloadRows(at: indexPathsToReload, with: .none)

        DispatchQueue.main.asyncAfter(seconds: 0.1) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension CurrencyPicker: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return suggestedCurrencies.count
        default:
            return otherCurrencies.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
        let currentCurrencyCode = TokenUser.current?.localCurrency

        let currency = indexPath.section == 0 ? suggestedCurrencies[indexPath.row] : otherCurrencies[indexPath.row]

        cell.textLabel?.text = "\(currency.name) (\(currency.code))"

        cell.accessoryType = currency.code == currentCurrencyCode ? .checkmark : .none
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return suggestedCurrencies.count > 0 ? Localized("currency_picker_header_suggested") : nil
        default:
            return otherCurrencies.count > 0 ? Localized("currency_picker_header_other") : nil
        }
    }
}
