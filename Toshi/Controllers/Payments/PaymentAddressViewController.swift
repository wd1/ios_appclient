import Foundation
import UIKit
import TinyConstraints
import CameraScanner

protocol PaymentAddressControllerDelegate: class {
    func paymentAddressControllerDidCancel(_ controller: PaymentAddressViewController)
    func paymentAddressControllerFinished(with address: String, on controller: PaymentAddressViewController)
}

class PaymentAddressViewController: UIViewController {

    private let valueInWei: NSDecimalNumber

    private var paymentAddress: String? {
        didSet {
            let isValid = validate(paymentAddress)
            navigationItem.rightBarButtonItem?.isEnabled = isValid
        }
    }

    weak var delegate: PaymentAddressControllerDelegate?

    private lazy var valueLabel: UILabel = {
        let value: String = EthereumConverter.fiatValueString(forWei: self.valueInWei, exchangeRate: ExchangeRateClient.exchangeRate)

        let view = UILabel()
        view.font = Theme.preferredTitle1()
        view.adjustsFontForContentSizeCategory = true
        view.textAlignment = .center
        view.adjustsFontSizeToFitWidth = true
        view.minimumScaleFactor = 0.5
        view.text = Localized("payment_send_prefix") + "\(value)"

        return view
    }()

    private lazy var descriptionLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.preferredRegular()
        view.textAlignment = .center
        view.numberOfLines = 0
        view.text = Localized("payment_send_description")
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    private lazy var addressInputView: PaymentAddressInputView = {
        let view = PaymentAddressInputView()
        view.delegate = self

        return view
    }()

    private lazy var scannerController: ScannerViewController = {
        let controller = ScannerController(instructions: Localized("qr_scanner_instructions"), types: [.qrCode])
        controller.delegate = self

        return controller
    }()

    private func validate(_ address: String?) -> Bool {
        let isValid: Bool
        if let address = address, EthereumAddress.validate(address) {
            isValid = true
        } else {
            isValid = false
        }

        return isValid
    }

    init(with valueInWei: NSDecimalNumber) {
        self.valueInWei = valueInWei
        super.init(nibName: nil, bundle: nil)

        navigationItem.backBarButtonItem = UIBarButtonItem.back
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Localized("payment_next_button"), style: .plain, target: self, action: #selector(nextBarButtonTapped(_:)))
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.viewBackgroundColor

        view.addSubview(valueLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(addressInputView)

        valueLabel.top(to: view, offset: 67)
        valueLabel.left(to: view, offset: 16)
        valueLabel.right(to: view, offset: -16)

        descriptionLabel.topToBottom(of: valueLabel, offset: 10)
        descriptionLabel.left(to: view, offset: 16)
        descriptionLabel.right(to: view, offset: -16)

        addressInputView.topToBottom(of: descriptionLabel, offset: 40)
        addressInputView.left(to: view)
        addressInputView.right(to: view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        addressInputView.addressTextField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        addressInputView.addressTextField.resignFirstResponder()

        guard isMovingFromParentViewController else { return }
        delegate?.paymentAddressControllerDidCancel(self)
    }

    @objc func nextBarButtonTapped(_ item: UIBarButtonItem) {
        goToConfirmation()
    }

    private func goToConfirmation() {
        guard let paymentAddress = paymentAddress, EthereumAddress.validate(paymentAddress) else { return }

        delegate?.paymentAddressControllerFinished(with: paymentAddress, on: self)
    }
}

extension PaymentAddressViewController: ScannerViewControllerDelegate {
    
    func scannerViewControllerDidCancel(_ controller: ScannerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func scannerViewController(_ controller: ScannerViewController, didScanResult result: String) {
        if let intent = QRCodeIntent(result: result) {
            switch intent {
            case .addContact(let username):
                let name = TokenUser.name(from: username)
                fillPaymentAddress(username: name)
            case .addressInput(let address):
                fillPaymentAddress(address: address)
            case .paymentRequest(_, let address, let username, _):
                if let username = username {
                    fillPaymentAddress(username: username)
                } else if let address = address {
                    fillPaymentAddress(address: address)
                }
            default:
                scannerController.startScanning()
            }
        } else {
            scannerController.startScanning()
        }
    }

    private func fillPaymentAddress(username: String) {
        IDAPIClient.shared.retrieveUser(username: username) { [weak self] contact in
            guard let contact = contact else {
                self?.scannerController.startScanning()

                return
            }
            self?.fillPaymentAddress(address: contact.paymentAddress)
        }
    }

    private func fillPaymentAddress(address: String) {
        paymentAddress = address
        self.addressInputView.paymentAddress = address
        SoundPlayer.playSound(type: .scanned)
        scannerController.dismiss(animated: true, completion: nil)
    }
}

extension PaymentAddressViewController: PaymentAddressInputDelegate {

    func didRequestScanner() {
        Navigator.presentModally(scannerController)
    }

    func didRequestSendPayment() {
        let isValid = validate(paymentAddress)
        navigationItem.rightBarButtonItem?.isEnabled = isValid
        
        if isValid {
            goToConfirmation()
        }
    }

    func didChangeAddress(_ text: String) {
        paymentAddress = text
    }
}
