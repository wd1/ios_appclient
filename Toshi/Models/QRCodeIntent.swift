import Foundation

enum QRCodeIntent {
    case webSignIn(loginToken: String)
    case paymentRequest(weiValue: String, address: String?, username: String?, memo: String?)
    case addContact(username: String)
    case addressInput(address: String)

    private static let webSignInPattern = "^web-signin:(\\w+)$"
    private static let addContactPattern = "^https?://[^\\.]+.toshi.org/add/@([^/\\?]+)"
    private static let paymentRequestPattern = "^https?://[^\\.]+.toshi.org/pay/@([^/\\?]+)"

    init?(result: String) {
        if let address = EthereumAddress(raw: result) {
            if let metadata = PaymentRequestMetadata(with: result) {
                self = .paymentRequest(weiValue: metadata.weiValue, address: address.normalized, username: nil, memo: metadata.memo)
            } else {
                self = .addressInput(address: address.normalized)
            }
        } else if let match = result.firstMatch(pattern: QRCodeIntent.webSignInPattern) {
            let loginToken = (result as NSString).substring(with: match.range(at: 1))
            self = .webSignIn(loginToken: loginToken)
        } else if let match = result.firstMatch(pattern: QRCodeIntent.addContactPattern) {
            let username = (result as NSString).substring(with: match.range(at: 1))
            self = .addContact(username: username)
        } else if let match = result.firstMatch(pattern: QRCodeIntent.paymentRequestPattern) {
            let username = (result as NSString).substring(with: match.range(at: 1))
            guard let metadata = PaymentRequestMetadata(with: result) else { return nil }
            self = .paymentRequest(weiValue: metadata.weiValue, address: nil, username: username, memo: metadata.memo)
        } else {
            CrashlyticsLogger.log("Unsupported QR code result", attributes: [.resultString: result])
            return nil
        }
    }
}
