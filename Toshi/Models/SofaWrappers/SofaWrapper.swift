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

@objc class SofaTypes: NSObject {
    @objc static let none = SofaType.none.rawValue
    @objc static let message = SofaType.message.rawValue
    @objc static let command = SofaType.command.rawValue
    @objc static let initialRequest = SofaType.initialRequest.rawValue
    @objc static let initialResponse = SofaType.initialResponse.rawValue
    @objc static let paymentRequest = SofaType.paymentRequest.rawValue
    @objc static let payment = SofaType.payment.rawValue
    @objc static let status = SofaType.status.rawValue
}

enum SofaType: String {
    case none = ""
    case message = "SOFA::Message:"
    case command = "SOFA::Command:"
    case initialRequest = "SOFA::InitRequest:"
    case initialResponse = "SOFA::Init:"
    case paymentRequest = "SOFA::PaymentRequest:"
    case payment = "SOFA::Payment:"
    case status = "SOFA::Status:"

    init(sofa: String?) {
        guard let sofa = sofa else {
            self = .none

            return
        }

        if sofa.hasPrefix(SofaType.message.rawValue) {
            self = .message
        } else if sofa.hasPrefix(SofaType.command.rawValue) {
            self = .command
        } else if sofa.hasPrefix(SofaType.initialRequest.rawValue) {
            self = .initialRequest
        } else if sofa.hasPrefix(SofaType.initialResponse.rawValue) {
            self = .initialResponse
        } else if sofa.hasPrefix(SofaType.paymentRequest.rawValue) {
            self = .paymentRequest
        } else if sofa.hasPrefix(SofaType.payment.rawValue) {
            self = .payment
        } else if sofa.hasPrefix(SofaType.status.rawValue) {
            self = .status
        } else {
            self = .none
        }
    }
}

protocol SofaWrapperProtocol {
    var type: SofaType { get }
}

class SofaWrapper: SofaWrapperProtocol {
    var type: SofaType {
        return .none
    }

    var content: String = ""

    var json: [String: Any] {
        return SofaWrapper.sofaContentToJSON(content, for: type) ?? [String: Any]()
    }

    static func wrapper(content: String) -> SofaWrapper {
        switch SofaType(sofa: content) {
        case .message:
            return SofaMessage(content: content)
        case .command:
            return SofaCommand(content: content)
        case .initialRequest:
            return SofaInitialRequest(content: content)
        case .initialResponse:
            return SofaInitialResponse(content: content)
        case .paymentRequest:
            return SofaPaymentRequest(content: content)
        case .payment:
            return SofaPayment(content: content)
        case .status:
            return SofaStatus(content: content)
        case .none:
            return SofaWrapper(content: "") // should probably crash instead
        }
    }

    init(content: String) {
        self.content = content
    }

    init(content json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else { fatalError() }
        guard let jsonString = String(data: data, encoding: .utf8) else { fatalError() }

        content = SofaWrapper.addSofaIdentifier(to: jsonString, for: type)
    }

    func removeFiatValueString() {
        var contentJSON = json
        contentJSON.removeValue(forKey: "fiatValueString")

        if let reducedContentSofaString = SofaWrapper.jsonToSofaContent(contentJSON, for: type) {
            content = reducedContentSofaString
        }
    }

    static func addFiatStringIfNecessary(to content: String, for sofaType: SofaType) -> String? {
        if SofaWrapper.contentContainsFiatValueString(content, for: sofaType) {
            return content
        } else {
            return SofaWrapper.addFiatValueToContent(content, for: sofaType)
        }
    }

    static func addFiatStringIfNecessary(to content: [String: Any], for sofaType: SofaType) -> [String: Any]? {
        guard content["fiatValueString"] as? String == nil else {
            // Fiat value is already in there
            return content
        }
        
        return SofaWrapper.addFiatValueToContent(content, for: sofaType)
    }

    static private func addFiatValueToContent(_ content: String, for sofaType: SofaType) -> String? {
        guard let json = sofaContentToJSON(content, for: sofaType) else { return nil }

        guard let extendedContentJSON = SofaWrapper.addFiatValueToContent(json, for: sofaType) else { return nil}
        guard let extendedContentSofaString = SofaWrapper.jsonToSofaContent(extendedContentJSON, for: sofaType) else { return nil}

        return extendedContentSofaString
    }

    static private func addFiatValueToContent(_ content: [String: Any], for sofaType: SofaType) -> [String: Any]? {
        guard let hexValue = content["value"] as? String else { return nil }

        var contentDictionary = content
        contentDictionary["fiatValueString"] = EthereumConverter.fiatValueStringWithCode(forWei: NSDecimalNumber(hexadecimalString: hexValue), exchangeRate: ExchangeRateClient.exchangeRate)

        return contentDictionary
    }

    static private func contentContainsFiatValueString(_ content: String, for sofaType: SofaType) -> Bool {
        guard let json = sofaContentToJSON(content, for: sofaType) else { return false }

        if json["fiatValueString"] as? String != nil {
            return true
        } else {
            return false
        }
    }

    static private func sofaContentToJSON(_ content: String, for sofaType: SofaType) -> [String: Any]? {
        let sofaBody = removeSofaIdentifier(from: content, for: sofaType)
        
        guard let data = sofaBody.data(using: .utf8) else { return nil}
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
        guard let json = jsonObject as? [String: Any] else { return nil}

        return json
    }

    static private func jsonToSofaContent(_ json: [String: Any], for sofaType: SofaType) -> String? {
        guard let extendedContentJSONData = try? JSONSerialization.data(withJSONObject: json, options: []) else { return nil }
        guard let extendedContentString = String(data: extendedContentJSONData, encoding: .utf8) else { return nil }

        return addSofaIdentifier(to: extendedContentString, for: sofaType)
    }

    static func removeSofaIdentifier(from content: String, for sofaType: SofaType) -> String {
        return content.replacingOccurrences(of: sofaType.rawValue, with: "")
    }

    static func addSofaIdentifier(to content: String, for sofaType: SofaType) -> String {
        var sofaString = sofaType.rawValue as String
        sofaString.append(content)

        return sofaString
    }
}
