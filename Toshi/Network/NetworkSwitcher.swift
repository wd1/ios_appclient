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
import KeychainSwift

extension NSNotification.Name {
    static let SwitchedNetworkChanged = NSNotification.Name(rawValue: "SwitchedNetworkChanged")
}

enum NetworkInfo {

    static let ActiveNetwork = "ActiveNetwork"

    struct Label {

        static let MainNet = Localized("mainnet-title")
        static let RopstenTestNetwork = Localized("ropsten-test-network-title")
        static let ToshiTestNetwork = Localized("toshi-test-network-title")
    }

    struct Path {
        static let MainNet = "https://ethereum.service.toshi.org"
        static let RopstenTestNetwork = "https://ethereum.development.service.toshi.org"
        static let ToshiTestNetwork = "https://ethereum.internal.service.toshi.org"
    }
}

enum Network: String {
    typealias RawValue = String

    case mainNet = "1"
    case ropstenTestNetwork = "3"
    case toshiTestNetwork = "116"

    var baseURL: String {
        switch self {
        case .mainNet:
            return NetworkInfo.Path.MainNet
        case .ropstenTestNetwork:
            return NetworkInfo.Path.RopstenTestNetwork
        case .toshiTestNetwork:
            return NetworkInfo.Path.ToshiTestNetwork
        }
    }

    var label: String {
        switch self {
        case .mainNet:
            return NetworkInfo.Label.MainNet
        case .ropstenTestNetwork:
            return NetworkInfo.Label.RopstenTestNetwork
        case .toshiTestNetwork:
            return NetworkInfo.Label.ToshiTestNetwork
        }
    }
}

final class NetworkSwitcher {
    static let shared = NetworkSwitcher()
    private let keychain = KeychainSwift()

    init() {
        keychain.synchronizable = false

        NotificationCenter.default.addObserver(self, selector: #selector(userDidSignOut(_:)), name: .UserDidSignOut, object: nil)
    }

    var activeNetwork: Network {
        guard let switched = self.switchedNetwork else {
            return defaultNetwork
        }

        return switched
    }

    var defaultNetworkBaseUrl: String {
        return defaultNetwork.baseURL
    }

    var isDefaultNetworkActive: Bool {
        return activeNetwork.rawValue == defaultNetwork.rawValue
    }

    var activeNetworkLabel: String {
        return activeNetwork.label
    }

    var activeNetworkBaseUrl: String {
        return activeNetwork.baseURL
    }

    var activeNetworkID: String {
        return activeNetwork.rawValue
    }

    var availableNetworks: [Network] {
        #if DEBUG || TOSHIDEV
            return [.ropstenTestNetwork, .toshiTestNetwork]
        #else
            return [.ropstenTestNetwork]
        #endif
    }

    func activateNetwork(_ network: Network?) {
        guard network?.rawValue != _switchedNetwork?.rawValue else { return }

        deregisterFromActiveNetworkPushNotificationsIfNeeded { success, _ in
            if success {
                self.switchedNetwork = network
            } else {
                DLog("Error deregistering - No connection")
            }
        }
    }

    private var _switchedNetwork: Network?
    private var switchedNetwork: Network? {
        set {
            _switchedNetwork = newValue

            guard let network = _switchedNetwork else {
                keychain.delete(NetworkInfo.ActiveNetwork)
                let notification = Notification(name: .SwitchedNetworkChanged)
                NotificationCenter.default.post(notification)

                return
            }

            registerForSwitchedNetworkPushNotifications { success, _ in
                if success {
                    self.keychain.set(network.rawValue, forKey: NetworkInfo.ActiveNetwork)

                    let notification = Notification(name: .SwitchedNetworkChanged)
                    NotificationCenter.default.post(notification)
                } else {
                    DLog("Error registering - No connection")
                    self.activateNetwork(nil)
                }
            }
        }
        get {
            guard let cachedNetwork = self._switchedNetwork else {
                guard let storedNetworkID = self.keychain.get(NetworkInfo.ActiveNetwork) else { return nil }
                _switchedNetwork = Network(rawValue: storedNetworkID)

                return _switchedNetwork
            }

            return cachedNetwork
        }
    }

    private func registerForSwitchedNetworkPushNotifications(completion: @escaping ((_ success: Bool, _ message: String?) -> Void)) {
        EthereumAPIClient.shared.registerForSwitchedNetworkPushNotificationsIfNeeded { success, _ in
            completion(success, nil)
        }
    }

    private func deregisterFromActiveNetworkPushNotificationsIfNeeded(completion: @escaping ((_ success: Bool, _ message: String?) -> Void)) {
        guard let switchedNetwork = self.switchedNetwork, switchedNetwork.rawValue != self.defaultNetwork.rawValue else {
            completion(true, nil)
            return
        }
        guard isDefaultNetworkActive == false && self.switchedNetwork != nil else {
            completion(true, nil)
            return
        }

        EthereumAPIClient.shared.deregisterFromSwitchedNetworkPushNotifications { success, _ in
            completion(success, nil)
        }
    }

    private var defaultNetwork: Network {
        #if DEBUG
            return .toshiTestNetwork
        #elseif TOSHIDEV
            return .ropstenTestNetwork
        #else
            return .mainNet
        #endif
    }

    @objc private func userDidSignOut(_: Notification) {
        activateNetwork(nil)
    }
}
