import Foundation

struct PaymentRequestMetadata {

    private(set) var weiValue: String
    private(set) var memo: String?

    init?(with query: String) {
        guard let metadata = URLComponents(string: query)?.queryItems else { return nil }

        var tempWei: String?

        for pair in metadata {
            guard let value = pair.value else { continue }
            switch pair.name {
            // "amount" is used by Jaxx and others as a float denominated in Ether
            case "amount":
                let ether = NSDecimalNumber(string: value)
                tempWei = ether.multiplying(byPowerOf10: EthereumConverter.weisToEtherPowerOf10Constant).toHexString
            // "value" is used by Toshi and others as an integer denominated in Wei
            case "value":
                tempWei = NSDecimalNumber(string: value).toHexString
            case "memo":
                memo = value
            default:
                continue
            }
        }

        if tempWei == nil { return nil }
        weiValue = tempWei!
    }
}
