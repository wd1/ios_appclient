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

final class SofaPaymentRequest: SofaWrapper {
    override var type: SofaType {
        return .paymentRequest
    }

    lazy var body: String = {
        self.json["body"] as? String ?? ""
    }()

    var fiatValueString: String {
        guard let string = self.json["fiatValueString"] as? String else { return "" }

        return string
    }

    var value: NSDecimalNumber {
        guard let hexValue = self.json["value"] as? String else { return NSDecimalNumber.zero }

        return NSDecimalNumber(hexadecimalString: hexValue)
    }

    var destinationAddress: String {
        return json["destinationAddress"] as? String ?? ""
    }

    convenience init(valueInWei: NSDecimalNumber) {

        let request: [String: Any] = [
            "value": valueInWei.toHexString,
            "destinationAddress": Cereal.shared.paymentAddress
        ]

        self.init(content: request)
    }

    override init(content: String) {
        guard let sofaContent = SofaWrapper.addFiatStringIfNecessary(to: content, for: SofaType.paymentRequest) else { fatalError() }

        super.init(content: sofaContent)
    }

    override init(content: [String: Any]) {
        guard let sofaContent = SofaWrapper.addFiatStringIfNecessary(to: content, for: SofaType.paymentRequest) else { fatalError() }

        super.init(content: sofaContent)
    }
}
