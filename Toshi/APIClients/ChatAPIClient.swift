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
import Teapot
import SweetFoundation

final class ChatAPIClient {

    static let shared: ChatAPIClient = ChatAPIClient()

    var teapot: Teapot

    var baseURL: URL

    private init() {
        guard let tokenChatServiceBaseURL = Bundle.main.object(forInfoDictionaryKey: "TokenChatServiceBaseURL") as? String, let url = URL(string: tokenChatServiceBaseURL) else { fatalError("TokenChatServiceBaseURL should be provided")}

        baseURL = url
        teapot = Teapot(baseURL: baseURL)
    }

    func fetchTimestamp(_ completion: @escaping ((Int) -> Void)) {

        self.teapot.get("/v1/accounts/bootstrap/") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else { fatalError("Could not retrieve timestamp from chat service.") }
                guard let json = json?.dictionary else { fatalError("JSON dictionary not found in payload") }
                guard let timestamp = json["timestamp"] as? Int else { fatalError("Timestamp not found in json payload or not an integer.") }

                DispatchQueue.main.async {
                    completion(timestamp)
                }
            case .failure(let json, let response, let error):
                DLog("\(error)")
                DLog("\(response)")
                DLog(String(describing: json))
            }
        }
    }

    func registerUser(completion: @escaping ((_ success: Bool) -> Void) = { (Bool) in }) {
        fetchTimestamp { timestamp in
            let cereal = Cereal.shared
            let parameters = UserBootstrapParameter()
            let path = "/v1/accounts/bootstrap"
            let payload = parameters.payload

            guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []), let payloadString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let hashedPayload = cereal.sha3WithID(string: payloadString)
            let message = "PUT\n\(path)\n\(timestamp)\n\(hashedPayload)"
            let signature = "0x\(cereal.signWithID(message: message))"

            let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]
            let requestParameter = RequestParameter(payload)

            self.teapot.put(path, parameters: requestParameter, headerFields: fields) { result in
                var succeeded = false

                switch result {
                case .success(_, let response):
                    guard response.statusCode == 204 else {
                        DLog("Could not register user. Status code \(response.statusCode)")
                        DispatchQueue.main.async {
                            completion(false)
                        }
                        return
                    }

                    TSAccountManager.sharedInstance().storeServerAuthToken(parameters.password, signalingKey: parameters.signalingKey)
                    ALog("Successfully registered chat user with address: \(cereal.address)")
                    succeeded = true
                case .failure(_, _, let error):
                    DLog("\(error)")
                    succeeded = false
                }

                DispatchQueue.main.async {
                    completion(succeeded)
                }
            }
        }
    }

    func authToken(for address: String, password: String) -> String {
        return "Basic \("\(address):\(password)".data(using: .utf8)!.base64EncodedString())"
    }
}
