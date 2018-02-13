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
import Teapot
import AwesomeCache

typealias TransactionSkeleton = (gas: String?, gasPrice: String?, transaction: String?)
typealias BalanceCompletion = ((_ balance: NSDecimalNumber, _ error: ToshiError?) -> Void)
typealias WalletItemsCompletion = ((_ items: [WalletItem], _ error: ToshiError?) -> Void)

final class EthereumAPIClient {

    static let shared: EthereumAPIClient = EthereumAPIClient()

    private var mainTeapot: Teapot

    private var switchedNetworkTeapot: Teapot

    private var activeTeapot: Teapot {
        if NetworkSwitcher.shared.isDefaultNetworkActive {
            return mainTeapot
        } else {
            return switchedNetworkTeapot
        }
    }

    private static var teapotUrl: String {
        return NetworkSwitcher.shared.activeNetworkBaseUrl
    }

    private static let CachedBalanceKey = "CachedBalanceKey"
    private lazy var cache: Cache<NSDecimalNumber> = {
        do {
            return try Cache<NSDecimalNumber>(name: "balanceCache")
        } catch {
            fatalError("Couldn't instantiate the balance cache")
        }
    }()

    convenience init(mockTeapot: MockTeapot) {
        self.init()
        self.switchedNetworkTeapot = mockTeapot
        self.mainTeapot = mockTeapot
    }

    private init() {
        mainTeapot = Teapot(baseURL: URL(string: NetworkSwitcher.shared.defaultNetworkBaseUrl)!)
        switchedNetworkTeapot = Teapot(baseURL: URL(string: NetworkSwitcher.shared.defaultNetworkBaseUrl)!)
    }

    func createUnsignedTransaction(parameters: [String: Any], completion: @escaping ((_ unsignedTransaction: String?, _ error: ToshiError?) -> Void)) {

        transactionSkeleton(for: parameters) { skeleton, error in
            let transaction = skeleton.transaction

            DispatchQueue.main.async {
                completion(transaction, error)
            }
        }
    }

    func transactionSkeleton(for parameters: [String: Any], completion: @escaping ((_ skeleton: TransactionSkeleton, _ error: ToshiError?) -> Void)) {

        let json = RequestParameter(parameters)

        self.activeTeapot.post("/v1/tx/skel", parameters: json) { result in
            var resultJson: [String: Any]?
            var resultError: ToshiError?

            switch result {
            case .success(let json, _):
                resultJson = json?.dictionary
            case .failure(_, _, let error):
                resultError = ToshiError(withTeapotError: error, errorDescription: Localized("payment_error_message"))
                DLog("\(error)")
            }

            DispatchQueue.main.async {
                let skeleton = (gas: resultJson?["gas"] as? String, gasPrice: resultJson?["gas_price"] as? String, transaction: resultJson?["tx"] as? String)
                completion(skeleton, resultError)
            }
        }
    }

    func sendSignedTransaction(originalTransaction: String, transactionSignature: String, completion: @escaping ((_ success: Bool, _ transactionHash: String?, _ error: ToshiError?) -> Void)) {
        let params = [
            "tx": originalTransaction,
            "signature": transactionSignature
        ]
        sendSignedTransaction(params: params, completion: completion)
    }

    func sendSignedTransaction(signedTransaction: String, completion: @escaping ((_ success: Bool, _ transactionHash: String?, _ error: ToshiError?) -> Void)) {
        let params = [
            "tx": signedTransaction
        ]
        sendSignedTransaction(params: params, completion: completion)
    }

    private func sendSignedTransaction(params: [String: String], completion: @escaping ((_ success: Bool, _ transactionHash: String?, _ error: ToshiError?) -> Void)) {

        timestamp(activeTeapot) { timestamp, error in
            guard let timestamp = timestamp else {
                DispatchQueue.main.async {
                    completion(false, nil, error)
                }
                return
            }

            let cereal = Cereal.shared
            let path = "/v1/tx"

            guard let data = try? JSONSerialization.data(withJSONObject: params, options: []), let payloadString = String(data: data, encoding: .utf8) else {
                DLog("Invalid payload, request could not be executed")
                DispatchQueue.main.async {
                    completion(false, nil, .invalidPayload)
                }
                return
            }

            let hashedPayload = cereal.sha3WithID(string: payloadString)
            let signature = "0x\(cereal.signWithID(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let headers: [String: String] = [
                "Token-ID-Address": cereal.address,
                "Token-Signature": signature,
                "Token-Timestamp": timestamp
            ]

            let json = RequestParameter(params)

            self.activeTeapot.post(path, parameters: json, headerFields: headers) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let json, _):
                        guard let hash = json?.dictionary?["tx_hash"] as? String else {
                            CrashlyticsLogger.log("Error recovering transaction hash")
                            fatalError("Error recovering transaction hash")
                        }
                        
                        completion(true, hash, nil)
                    case .failure(let json, _, let error):
                        guard let jsonError = (json?.dictionary?["errors"] as? [[String: Any]])?.first else {
                            completion(false, nil, ToshiError(withTeapotError: error))
                            return
                        }

                        completion(false, nil, ToshiError(withTeapotError: error, errorDescription: jsonError["message"] as? String))
                    }
                }
            }
        }
    }

    func getBalance(address: String = Cereal.shared.paymentAddress, cachedBalanceCompletion: @escaping BalanceCompletion = { balance, _ in }, fetchedBalanceCompletion: @escaping BalanceCompletion) {

        let cachedBalance: NSDecimalNumber = self.cache.object(forKey: EthereumAPIClient.CachedBalanceKey) ?? .zero
        cachedBalanceCompletion(cachedBalance, nil)

        self.activeTeapot.get("/v1/balance/\(address)") { [weak self] (result: NetworkResult) in
            var balance: NSDecimalNumber = .zero
            var resultError: ToshiError?

            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else {
                    DispatchQueue.main.async {
                        fetchedBalanceCompletion(0, .invalidResponseStatus(response.statusCode))
                    }
                    
                    return
                }
                guard let json = json?.dictionary else {
                    DispatchQueue.main.async {
                        fetchedBalanceCompletion(0, .invalidResponseJSON)
                    }
                    
                    return
                }

                let unconfirmedBalanceString = json["unconfirmed_balance"] as? String ?? "0"
                let unconfirmedBalance = NSDecimalNumber(hexadecimalString: unconfirmedBalanceString)

                TokenUser.current?.balance = unconfirmedBalance
                balance = unconfirmedBalance

            case .failure(_, _, let error):
                resultError = ToshiError(withTeapotError: error)
                DLog("\(error)")
            }

            DispatchQueue.main.async {
                self?.cache.setObject(balance, forKey: EthereumAPIClient.CachedBalanceKey)
                fetchedBalanceCompletion(balance, resultError)
            }
        }
    }

    func getCollectible(address: String = Cereal.shared.paymentAddress, contractAddress: String, completion: @escaping ((Collectible?, ToshiError?) -> Void)) {
        self.activeTeapot.get("/v1/collectibles/\(address)/\(contractAddress)") { result in
            var resultError: ToshiError?
            var resultItem: Collectible?

            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else {
                    DispatchQueue.main.async {
                        completion(nil, .invalidResponseStatus(response.statusCode))
                    }

                    return
                }

                guard let data = json?.data else {
                    DispatchQueue.main.async {
                        completion(nil, .invalidPayload)
                    }
                    return
                }

                let collectible: Collectible
                do {
                    let jsonDecoder = JSONDecoder()
                    collectible = try jsonDecoder.decode(Collectible.self, from: data)
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, .invalidResponseJSON)
                    }
                    return
                }

                resultItem = collectible

            case .failure(_, _, let error):
                resultError = ToshiError(withTeapotError: error)
                DLog("\(error)")
            }

            DispatchQueue.main.async {
                completion(resultItem, resultError)
            }
        }
    }

    func getCollectibles(address: String = Cereal.shared.paymentAddress, completion: @escaping WalletItemsCompletion) {

        self.activeTeapot.get("/v1/collectibles/\(address)") { (result: NetworkResult) in
            var resultError: ToshiError?
            var resultItems: [Collectible] = []

            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else {
                    DispatchQueue.main.async {
                        completion([], .invalidResponseStatus(response.statusCode))
                    }

                    return
                }

                guard let data = json?.data else {
                    DispatchQueue.main.async {
                        completion([], .invalidPayload)
                    }
                    return
                }

                let collectiblesResults: CollectibleResults
                do {
                    let jsonDecoder = JSONDecoder()
                    collectiblesResults = try jsonDecoder.decode(CollectibleResults.self, from: data)
                } catch {
                    DispatchQueue.main.async {
                        completion([], .invalidResponseJSON)
                    }
                    return
                }

                resultItems.append(contentsOf: collectiblesResults.collectibles)

            case .failure(_, _, let error):
                resultError = ToshiError(withTeapotError: error)
                DLog("\(error)")
            }

            DispatchQueue.main.async {
                completion(resultItems, resultError)
            }
        }
    }

    func getTokens(address: String = Cereal.shared.paymentAddress, completion: @escaping WalletItemsCompletion) {

        self.activeTeapot.get("/v1/tokens/\(address)") { (result: NetworkResult) in
            var resultError: ToshiError?
            var resultItems: [Token] = []

            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else {
                    DispatchQueue.main.async {
                        completion([], .invalidResponseStatus(response.statusCode))
                    }

                    return
                }

                guard let data = json?.data else {
                    DispatchQueue.main.async {
                        completion([], .invalidPayload)
                    }
                    return
                }

                let tokenResults: TokenResults
                do {
                    let jsonDecoder = JSONDecoder()
                    tokenResults = try jsonDecoder.decode(TokenResults.self, from: data)
                } catch {
                    DispatchQueue.main.async {
                        completion([], .invalidResponseJSON)
                    }
                    return
                }

                resultItems.append(contentsOf: tokenResults.tokens)

            case .failure(_, _, let error):
                resultError = ToshiError(withTeapotError: error)
                DLog("\(error)")
            }

            DispatchQueue.main.async {
                completion(resultItems, resultError)
            }
        }
    }

    func registerForMainNetworkPushNotifications() {
        timestamp(mainTeapot) { timestamp, _ in
            guard let timestamp = timestamp else { return }
            self.registerForPushNotifications(timestamp, teapot: self.mainTeapot) { _, _ in }
        }
    }

    func registerForSwitchedNetworkPushNotificationsIfNeeded(completion: ((_ success: Bool, _ message: String?) -> Void)? = nil) {
        guard NetworkSwitcher.shared.isDefaultNetworkActive == false else {
            completion?(true, nil)
            return
        }

        switchedNetworkTeapot.baseURL = URL(string: NetworkSwitcher.shared.activeNetworkBaseUrl)!

        timestamp(switchedNetworkTeapot) { timestamp, _ in
            guard let timestamp = timestamp else { return }
            self.registerForPushNotifications(timestamp, teapot: self.switchedNetworkTeapot, completion: completion)
        }
    }

    func deregisterFromMainNetworkPushNotifications() {
        timestamp(mainTeapot) { timestamp, _ in
            guard let timestamp = timestamp else { return }
            self.deregisterFromPushNotifications(timestamp, teapot: self.mainTeapot)
        }
    }

    func deregisterFromSwitchedNetworkPushNotifications(completion: @escaping ((_ success: Bool, _ message: String?) -> Void) = { (Bool, String) in }) {

        timestamp(switchedNetworkTeapot) { timestamp, _ in
            guard let timestamp = timestamp else { return }
            self.deregisterFromPushNotifications(timestamp, teapot: self.switchedNetworkTeapot, completion: completion)
        }
    }

    private func timestamp(_ teapot: Teapot, _ completion: @escaping ((_ timestamp: String?, _ error: ToshiError?) -> Void)) {
        teapot.get("/v1/timestamp") { (result: NetworkResult) in
            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary else { fatalError() }
                guard let timestamp = json["timestamp"] as? Int else { fatalError("Timestamp should be an integer") }

                completion(String(timestamp), nil)
            case .failure(_, _, let error):
                completion(nil, ToshiError(withTeapotError: error))
                DLog("\(error)")
            }
        }
    }

    private func registerForPushNotifications(_ timestamp: String, teapot: Teapot, completion: ((_ success: Bool, _ message: String?) -> Void)? = nil) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

            let cereal = Cereal.shared
            let path = "/v1/apn/register"
            let address = cereal.address
            let params = ["registration_id": appDelegate.token, "address": cereal.paymentAddress]

            guard let data = try? JSONSerialization.data(withJSONObject: params, options: []), let payloadString = String(data: data, encoding: .utf8) else {
                completion?(false, "Invalid payload, request could not be executed")
                return
            }

            let hashedPayload = cereal.sha3WithID(string: payloadString)
            let signature = "0x\(cereal.signWithID(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let headerFields: [String: String] = [
                "Token-ID-Address": address,
                "Token-Signature": signature,
                "Token-Timestamp": timestamp
            ]

            let json = RequestParameter(params)

            DispatchQueue.global().async {
                teapot.post(path, parameters: json, headerFields: headerFields) { result in
                    switch result {
                    case .success(let json, let response):
                        DLog("\n +++ Registered for :\(teapot.baseURL)")
                        DispatchQueue.main.async {
                            completion?(true, "json: \(json?.dictionary ?? [String: Any]()) response: \(response)")
                        }
                    case .failure(let json, let response, let error):
                        DLog("\(error)")
                        DispatchQueue.main.async {
                            completion?(false, "json: \(json?.dictionary ?? [String: Any]()) response: \(response), error: \(error)")
                        }
                    }
                }
            }
        }
    }

    private func deregisterFromPushNotifications(_ timestamp: String, teapot: Teapot, completion: @escaping ((_ success: Bool, _ message: String?) -> Void) = { (Bool, String) in }) {

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        let cereal = Cereal.shared
        let address = cereal.address
        let path = "/v1/apn/deregister"

        let params = ["registration_id": appDelegate.token, "address": cereal.paymentAddress]

        guard let data = try? JSONSerialization.data(withJSONObject: params, options: []), let payloadString = String(data: data, encoding: .utf8) else {
            completion(false, "Invalid payload, request could not be executed")
            return
        }

        let hashedPayload = cereal.sha3WithID(string: payloadString)
        let signature = "0x\(cereal.signWithID(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

        let headerFields: [String: String] = [
            "Token-ID-Address": address,
            "Token-Signature": signature,
            "Token-Timestamp": timestamp
        ]

        let json = RequestParameter(params)

            teapot.post(path, parameters: json, headerFields: headerFields) { result in
                switch result {
                case .success(let json, let response):
                    DLog("\n --- DE-registered from :\(teapot.baseURL)")
                    DispatchQueue.main.async {
                        completion(true, "json:\(json?.dictionary ?? [String: Any]()), response: \(response)")
                    }
                case .failure(let json, let response, let error):
                    DLog("\(error)")
                    DispatchQueue.main.async {
                        completion(false, "json:\(json?.dictionary ?? [String: Any]()), response: \(response), error: \(error)")
                    }
                }
            }
    }
}
