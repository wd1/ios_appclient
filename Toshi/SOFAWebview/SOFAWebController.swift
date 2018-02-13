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
import WebKit
import TinyConstraints

final class SOFAWebController: UIViewController {

    enum Method: String {
        case getAccounts
        case signTransaction
        case signMessage
        case signPersonalMessage
        case publishTransaction
        case approveTransaction
    }

    private var etherAPIClient: EthereumAPIClient {
        return EthereumAPIClient.shared
    }

    private let rcpUrl = ToshiWebviewRPCURLPath
    private var paymentRouter: PaymentRouter?

    private var currentTransactionSignCallbackId: String?

    private lazy var activityView = self.defaultActivityIndicator()
    
    private lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        
        var js = "window.SOFA = {config: {accounts: ['"+Cereal.shared.paymentAddress+"'], rcpUrl: '" + self.rcpUrl + "'}}; "
        
        if let filepath = Bundle.main.path(forResource: "sofa-web3", ofType: "js") {
            do {
                js += try String(contentsOfFile: filepath)
                DLog("Loaded sofa.js")
            } catch {
                DLog("Failed to load sofa.js")
            }
        } else {
            DLog("Sofa.js not found in bundle")
        }
        
        var userScript: WKUserScript = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)

        scriptMessageHandlersNames.forEach { handlerName in
            configuration.userContentController.add(self, name: handlerName)
        }
        
        configuration.userContentController.addUserScript(userScript)

        return configuration
    }()

    private lazy var webView: WKWebView = {
        let view = WKWebView(frame: self.view.frame, configuration: self.webViewConfiguration)
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.isScrollEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.navigationDelegate = self
        view.uiDelegate = self

        return view
    }()

    private lazy var backButton: UIButton = {
        let view = UIButton(type: .custom)
        view.bounds.size = CGSize(width: 44, height: 44)
        view.setImage(#imageLiteral(resourceName: "web_back").withRenderingMode(.alwaysTemplate), for: .normal)
        view.addTarget(self, action: #selector(self.didTapBackButton), for: .touchUpInside)

        return view
    }()

    private lazy var forwardButton: UIButton = {
        let view = UIButton(type: .custom)
        view.bounds.size = CGSize(width: 44, height: 44)
        view.setImage(#imageLiteral(resourceName: "web_forward").withRenderingMode(.alwaysTemplate), for: .normal)
        view.addTarget(self, action: #selector(self.didTapForwardButton), for: .touchUpInside)

        return view
    }()

    private lazy var backBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(customView: self.backButton)
    }()

    private lazy var forwardBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(customView: self.forwardButton)
    }()

    private lazy var toolbar: UIToolbar = {
        let view = UIToolbar(withAutoLayout: true)
        let spacing = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        view.items = [spacing, self.backBarButtonItem, spacing, self.forwardBarButtonItem, spacing]

        return view
    }()

    private lazy var scriptMessageHandlersNames: [String] = {
        return [Method.getAccounts.rawValue,
                Method.signPersonalMessage.rawValue,
                Method.signMessage.rawValue,
                Method.signTransaction.rawValue,
                Method.publishTransaction.rawValue,
                Method.approveTransaction.rawValue]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        view.addSubview(toolbar)

        toolbar.height(44)
        toolbar.bottom(to: layoutGuide())
        toolbar.left(to: view)
        toolbar.right(to: view)

        webView.top(to: view)
        webView.left(to: view)
        webView.right(to: view)
        webView.bottomToTop(of: toolbar)

        hidesBottomBarWhenPushed = true

        setupActivityIndicator()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard isMovingFromParentViewController else { return }

        scriptMessageHandlersNames.forEach { handlerName in
            webViewConfiguration.userContentController.removeScriptMessageHandler(forName: handlerName)
        }
    }

    func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    init() {
        super.init(nibName: nil, bundle: nil)

        loadViewIfNeeded()
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    @objc
    private func didTapBackButton() {
        webView.goBack()
    }

    @objc
    private func didTapForwardButton() {
        webView.goForward()
    }
}

extension SOFAWebController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {

        // Some webservers are asking for Server Trust Authentication, we need to properly respond with the appropriate action. Which is using SecTrustRef to authenticate it

        let protectionSpace = challenge.protectionSpace

        guard protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let trust = protectionSpace.serverTrust else {
                completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
                return
        }

        let urlCredentials = URLCredential(trust: trust)
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, urlCredentials)
    }
}

extension SOFAWebController: WKScriptMessageHandler {
    private func jsCallback(callbackId: String, payload: String) {
        let js = "SOFA.callback(\"" + callbackId + "\",\"" + payload + "\")"

        webView.evaluateJavaScript("javascript:" + js) { jsReturnValue, error in
            if let error = error {
                DLog("Error: \(error)")
            } else if let newCount = jsReturnValue as? Int {
                DLog("Returned value: \(newCount)")
            } else {
                DLog("No return from JS")
            }
        }
    }

    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let method = Method(rawValue: message.name) else { return DLog("failed \(message.name)") }
        guard let callbackId = (message.body as? NSDictionary)?.value(forKey: "callback") as? String else { return DLog("missing callback id") }

        switch method {
        case .getAccounts:
            let payload = "{\\\"error\\\": null, \\\"result\\\": [\\\"" + Cereal.shared.paymentAddress + "\\\"]}"
            jsCallback(callbackId: callbackId, payload: payload)
        case .signPersonalMessage:
            guard let messageBody = message.body as? [String: Any], let msgParams = messageBody["msgParams"] as? [String: Any], let messageEncodedString = msgParams["data"] as? String else {
                jsCallback(callbackId: callbackId, payload: "{\\\"error\\\": \\\"Invalid Message Body\\\"}")
                return
            }

            if let messageData = messageEncodedString.hexadecimalData, let decodedString = String(data: messageData, encoding: .utf8) {

                DispatchQueue.main.async {
                    self.presentPersonalMessageSignAlert(decodedString, callbackId: callbackId, signHandler: { [weak self] returnedCallbackId in
                        let composedString = "\u{0019}Ethereum Signed Message:\n" + String(messageData.count) + decodedString

                        if let resultData = composedString.data(using: .utf8) {
                            var signature = "0x\(Cereal.shared.signWithWallet(hex: resultData.hexEncodedString()))"

                            let index = signature.index(signature.startIndex, offsetBy: 130)
                            if let suffix = Int(signature.suffix(from: index)) {
                                let resultSuffix = suffix + 27

                                let truncated = signature.dropLast(2)
                                let suffixHex = String(format: "%2X", resultSuffix)

                                signature = truncated + suffixHex
                                self?.jsCallback(callbackId: returnedCallbackId, payload: "{\\\"result\\\":\\\"\(signature)\\\"}")
                            }
                        }
                    })
                }
            } else {
                jsCallback(callbackId: callbackId, payload: "{\\\"error\\\": \\\"Invalid Message Body\\\"}")
            }

        case .signMessage:
            guard let messageBody = message.body as? [String: Any], let msgParams = messageBody["msgParams"] as? [String: Any], let messageEncodedString = msgParams["data"] as? String, messageEncodedString.isValidSha3Hash else {
                jsCallback(callbackId: callbackId, payload: "{\\\"error\\\": \\\"Invalid Message Body\\\"}")
                return
            }

            DispatchQueue.main.async {
                self.presentPersonalMessageSignAlert("\(Localized("eth_sign_warning"))\n\n\(messageEncodedString)", callbackId: callbackId, signHandler: { [weak self] returnedCallbackId in

                    var signature = "0x\(Cereal.shared.signWithWallet(hash: messageEncodedString))"

                    let index = signature.index(signature.startIndex, offsetBy: 130)
                    if let suffix = Int(signature.suffix(from: index)) {
                        let resultSuffix = suffix + 27

                        let truncated = signature.dropLast(2)
                        let suffixHex = String(format: "%2X", resultSuffix)

                        signature = truncated + suffixHex
                        self?.jsCallback(callbackId: returnedCallbackId, payload: "{\\\"result\\\":\\\"\(signature)\\\"}")
                    }
                })
            }

        case .signTransaction:
            guard let messageBody = message.body as? [String: Any], let transaction = messageBody["tx"] as? [String: Any] else {
                jsCallback(callbackId: callbackId, payload: "{\\\"error\\\": \\\"Invalid Message Body\\\"}")
                return
            }

            var parameters: [String: Any] = [:]
            if let from = transaction[PaymentParameters.from] {
                parameters[PaymentParameters.from] = from
            }
            if let to = transaction[PaymentParameters.to] {
                parameters[PaymentParameters.to] = to
            }
            if let value = transaction[PaymentParameters.value] {
                parameters[PaymentParameters.value] = value
            } else {
                parameters[PaymentParameters.value] = "0x0"
            }
            if let data = transaction[PaymentParameters.data] {
                parameters[PaymentParameters.data] = data
            }
            if let gas = transaction[PaymentParameters.gas] {
                parameters[PaymentParameters.gas] = gas
            }
            if let gasPrice = transaction[PaymentParameters.gasPrice] {
                parameters[PaymentParameters.gasPrice] = gasPrice
            }
            if let nonce = transaction[PaymentParameters.nonce] {
                parameters[PaymentParameters.nonce] = nonce
            }

            if let to = transaction[PaymentParameters.to] as? String, let value = parameters[PaymentParameters.value] as? String {

                showActivityIndicator()

                IDAPIClient.shared.findUserWithPaymentAddress(to, completion: { [weak self] user, _ in
                    let webViewTitle = self?.webView.title

                    self?.hideActivityIndicator()

                    guard let url = self?.webView.url else {
                        assertionFailure("Can't retrieve Webview url")
                        return
                    }

                    var userInfo = UserInfo(address: to, paymentAddress: to, avatarPath: nil, name: webViewTitle, username: to, isLocal: false)

                    //we do not have image from a website yet
                    let dappInfo = DappInfo(url, "", webViewTitle)

                    if let user = user {
                        userInfo.avatarPath = user.avatarPath
                        userInfo.username = user.username
                        userInfo.name = user.name
                        userInfo.isLocal = true
                    }

                    let decimalValue = NSDecimalNumber(hexadecimalString: value)
                    let fiatValueString = EthereumConverter.fiatValueString(forWei: decimalValue, exchangeRate: ExchangeRateClient.exchangeRate)
                    let ethValueString = EthereumConverter.ethereumValueString(forWei: decimalValue)
                    let messageText = String(format: Localized("payment_confirmation_warning_message"), fiatValueString, ethValueString, user?.name ?? to)

                    self?.presentPaymentConfirmation(with: messageText, parameters: parameters, userInfo: userInfo, dappInfo: dappInfo, callbackId: callbackId)
                })
            }
        case .publishTransaction:
            guard let messageBody = message.body as? [String: Any],
                  let signedTransaction = messageBody["rawTx"] as? String else {
                jsCallback(callbackId: callbackId, payload: "{\\\"error\\\": \\\"Invalid Message Body\\\"}")
                return
            }

            self.sendSignedTransaction(signedTransaction, with: callbackId, completion: { [weak self] returnedCallbackId, payload in
                self?.jsCallback(callbackId: returnedCallbackId, payload: payload)
            })

        case .approveTransaction:
            let payload = "{\\\"error\\\": null, \\\"result\\\": true}"
            jsCallback(callbackId: callbackId, payload: payload)
        }
    }

    private func sendSignedTransaction(_ transaction: String, with callbackId: String, completion: @escaping ((String, String) -> Void)) {

        etherAPIClient.sendSignedTransaction(signedTransaction: transaction) { success, transactionHash, error in
            guard success, let txHash = transactionHash else {
                completion(callbackId, "{\\\"error\\\": \\\"\(error?.description ?? "Error sending transaction")\\\"}")

                return
            }

            completion(callbackId, "{\\\"result\\\":\\\"\(txHash)\\\"}")
        }
    }

    private func presentPaymentConfirmation(with messageText: String, parameters: [String: Any], userInfo: UserInfo, dappInfo: DappInfo, callbackId: String) {

        guard currentTransactionSignCallbackId == nil else {
            // Already signing a transaction
            return
        }

        currentTransactionSignCallbackId = callbackId

        let paymentRouter = PaymentRouter(parameters: parameters, shouldSendSignedTransaction: false)
        paymentRouter.delegate = self

        paymentRouter.userInfo = userInfo
        paymentRouter.dappInfo = dappInfo
        paymentRouter.present()

        self.paymentRouter = paymentRouter
    }

    private func approvePayment(with parameters: [String: Any], userInfo _: UserInfo, transaction: String?, callbackId: String) {

        let payload: String

        if let transaction = transaction, let encodedSignedTransaction = Cereal.shared.signEthereumTransactionWithWallet(hex: transaction) {
            payload = "{\\\"result\\\":\\\"\(encodedSignedTransaction)\\\"}"
        } else {
            payload = SOFAResponseConstants.skeletonErrorJSON
        }

        jsCallback(callbackId: callbackId, payload: payload)

        currentTransactionSignCallbackId = nil
    }

    private func presentPersonalMessageSignAlert(_ message: String, callbackId: String, signHandler: @escaping ((String) -> Void)) {

        let alert = UIAlertController(title: Localized("sign_alert_title"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized("cancel_action_title"), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: Localized("sign_action_title"), style: .default, handler: { _ in
            signHandler(callbackId)
        }))

        Navigator.presentModally(alert)
    }
}

extension SOFAWebController: ActivityIndicating {
    var activityIndicator: UIActivityIndicatorView {
        return activityView
    }
}

extension SOFAWebController: PaymentRouterDelegate {

    func paymentRouterDidSucceedPayment(_ paymentRouter: PaymentRouter, parameters: [String: Any], transactionHash: String?, unsignedTransaction: String?, error: ToshiError?) {

        guard let callbackId = currentTransactionSignCallbackId else {
            let message = "No current signed transcation callBack Id on SOFAWebVontroller when payment router finished"
            assertionFailure(message)
            CrashlyticsLogger.nonFatal(message, error: nil, attributes: parameters)
            return
        }

        guard let userInfo = paymentRouter.userInfo else {
            let message = "No user info found on SOFAWebController payment router after it finished"
            assertionFailure(message)
            CrashlyticsLogger.nonFatal(message, error: nil, attributes: parameters)
            return
        }

        guard error == nil else {
            let payload = SOFAResponseConstants.skeletonErrorJSON
            jsCallback(callbackId: callbackId, payload: payload)

            return
        }

        approvePayment(with: parameters, userInfo: userInfo, transaction: unsignedTransaction, callbackId: callbackId)
    }

    func paymentRouterDidCancel(paymentRouter: PaymentRouter) {

        guard let callbackId = currentTransactionSignCallbackId else {
            let message = "No current signed transcation callBack Id on SOFAWebVontroller when payment router finished"
            assertionFailure(message)
            CrashlyticsLogger.log(message)
            return
        }

        let payload = "{\\\"error\\\": \\\"Transaction declined by user\\\", \\\"result\\\": null}"
        jsCallback(callbackId: callbackId, payload: payload)

        currentTransactionSignCallbackId = nil
    }
}

extension SOFAWebController: WKUIDelegate {

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }

        return nil
    }
}

struct SOFAResponseConstants {
    static let skeletonErrorJSON = "{\\\"error\\\": \\\"Error constructing tx skeleton\\\", \\\"result\\\": null}"
}
