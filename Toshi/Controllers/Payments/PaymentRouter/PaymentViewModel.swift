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

struct PaymentViewModel {

    var recipientAddress: String? {
        set {
            parameters[PaymentParameters.to] = newValue
        }
        get {
            return parameters[PaymentParameters.to] as? String
        }
    }

    var value: NSDecimalNumber? {
        set {
            parameters[PaymentParameters.value] = newValue?.toHexString
        }
        get {
            guard let hexValue = parameters[PaymentParameters.value] as? String else { return nil }

            return NSDecimalNumber(hexadecimalString: hexValue)
        }
    }

    var from: String {
        return Cereal.shared.address
    }

    private(set) var data: String? {
        set {
            parameters[PaymentParameters.data] = newValue
        }
        get {
            return parameters[PaymentParameters.data] as? String
        }
    }

    private(set) var gas: String? {
        set {
            parameters[PaymentParameters.gas] = newValue
        }
        get {
            return parameters[PaymentParameters.gas] as? String
        }
    }

    private(set) var gasPrice: String? {
        set {
            parameters[PaymentParameters.gasPrice] = newValue
        }
        get {
            return parameters[PaymentParameters.gasPrice] as? String
        }
    }

    private(set) var nonce: String? {
        set {
            parameters[PaymentParameters.nonce] = newValue
        }
        get {
            return parameters[PaymentParameters.nonce] as? String
        }
    }

    private(set) var parameters: [String: Any]
    
    init(parameters: [String: Any]) {

        self.parameters = parameters
        self.parameters[PaymentParameters.from] = Cereal.shared.paymentAddress
    }
}
