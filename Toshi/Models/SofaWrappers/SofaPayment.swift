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

final class SofaPayment: SofaWrapper {

    enum Status: String {
        case unconfirmed
        case confirmed
        case error
    }

    var status: Status {
        guard let status = self.json["status"] as? String else { return .unconfirmed }
        return Status(rawValue: status) ?? .unconfirmed
    }

    var recipientAddress: String? {
        return self.json["toAddress"] as? String
    }

    var senderAddress: String? {
        return self.json["fromAddress"] as? String
    }

    override var type: SofaType {
        return .payment
    }

    var value: NSDecimalNumber {
        guard let hexValue = self.json["value"] as? String else { return NSDecimalNumber.zero }

        return NSDecimalNumber(hexadecimalString: hexValue)
    }

    var fiatValueString: String {
        guard let string = self.json["fiatValueString"] as? String else { return "" }

        return string
    }

    convenience init(txHash: String, valueHex: String) {

        let payment: [String: String] = [
            "status": Status.unconfirmed.rawValue,
            "txHash": txHash,
            "value": valueHex
        ]

        self.init(content: payment)
    }

    override init(content: String) {
        guard let sofaContent = SofaWrapper.addFiatStringIfNecessary(to: content, for: SofaType.payment) else { fatalError() }

        super.init(content: sofaContent)
    }

    override init(content: [String: Any]) {
        guard let sofaContent = SofaWrapper.addFiatStringIfNecessary(to: content, for: SofaType.payment) else { fatalError() }

        super.init(content: sofaContent)
    }
}
