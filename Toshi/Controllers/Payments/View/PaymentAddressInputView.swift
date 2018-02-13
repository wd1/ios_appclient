import Foundation
import UIKit
import TinyConstraints

protocol PaymentAddressInputDelegate: class {
    func didRequestScanner()
    func didRequestSendPayment()
    func didChangeAddress(_ text: String)
}

final class PaymentAddressInputView: UIView {

    weak var delegate: PaymentAddressInputDelegate?

    var paymentAddress: String? {
        didSet {
            addressTextField.text = paymentAddress
        }
    }

    private lazy var topDivider: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.borderColor

        return view
    }()

    private(set) lazy var addressTextField: UITextField = {
        let view = UITextField()
        view.font = Theme.preferredRegular()
        view.delegate = self
        view.placeholder = Localized("payment_input_placeholder")
        view.returnKeyType = .send
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    private lazy var qrButton: UIButton = {
        let image = UIImage(named: "qr-icon")?.withRenderingMode(.alwaysTemplate)

        let view = UIButton()
        view.contentMode = .center
        view.tintColor = Theme.darkTextColor
        view.setImage(image, for: .normal)
        view.addTarget(self, action: #selector(qrButtonTapped(_:)), for: .touchUpInside)

        return view
    }()

    private lazy var bottomDivider: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.borderColor

        return view
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(topDivider)
        addSubview(addressTextField)
        addSubview(qrButton)
        addSubview(bottomDivider)

        topDivider.top(to: self)
        topDivider.left(to: self)
        topDivider.right(to: self)
        topDivider.height(.lineHeight)

        addressTextField.left(to: self, offset: 16)
        addressTextField.centerY(to: self)

        qrButton.topToBottom(of: topDivider)
        qrButton.leftToRight(of: addressTextField)
        qrButton.bottomToTop(of: bottomDivider)
        qrButton.right(to: self)
        qrButton.width(50)
        qrButton.height(58)

        bottomDivider.left(to: self, offset: 16)
        bottomDivider.bottom(to: self)
        bottomDivider.right(to: self, offset: -16)
        bottomDivider.height(.lineHeight)
    }

    @objc func qrButtonTapped(_ button: UIButton) {
        delegate?.didRequestScanner()
    }
}

extension PaymentAddressInputView: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.didRequestSendPayment()
        return false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let textFieldText: NSString = (textField.text ?? "") as NSString
        let textAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
        delegate?.didChangeAddress(textAfterUpdate)

        return true
    }
}
