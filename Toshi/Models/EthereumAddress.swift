import Foundation

struct EthereumAddress {
    enum AddressFormat: String {
        case icap = "iban:xe(\\w{2})(\\w{31})"
        case ethereumHex = "ethereum:0x(\\w{40})"
        case hex = "0x(\\w{40})"
        case unprefixedHex = "(\\w{40})"

        init?(_ raw: String) {
            for format in [AddressFormat.icap, AddressFormat.ethereumHex, AddressFormat.hex, AddressFormat.unprefixedHex] {
                if raw.range(of: format.rawValue, options: NSString.CompareOptions.regularExpression) != nil {
                    self = format
                    return
                }
            }
            return nil
        }
    }

    let normalized: String

    init?(raw: String) {
        let input = raw.lowercased()

        guard let format = AddressFormat(input) else { return nil }
        guard let match = input.firstMatch(pattern: format.rawValue) else { return nil }

        switch format {
        case .ethereumHex, .hex, .unprefixedHex:
            let address = (input as NSString).substring(with: match.range(at: 1))
            normalized = "0x" + address.lowercased()
        case .icap:
            guard match.numberOfRanges == 3 else { return nil }
            let accountIdentifier = (input as NSString).substring(with: match.range(at: 2))
            guard let address = accountIdentifier.base36to16() else { return nil }
            normalized = "0x" + address.lowercased()
        }
    }

    static func validate(_ address: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "0x[a-fA-F0-9]{40}")
            let results = regex.matches(in: address, range: NSRange(address.startIndex..., in: address))
            return results.count == 1
        } catch let error {
            fatalError("invalid regex: \(error.localizedDescription)")
        }
    }
}

private extension String {
    static let base36Alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"
    static var base36AlphabetMap: [Character: Int] {
        var reverseLookup = [Character: Int]()
        for characterIndex in 0..<base36Alphabet.length {
            let character = base36Alphabet[base36Alphabet.index(base36Alphabet.startIndex, offsetBy: characterIndex)]
            reverseLookup[character] = characterIndex
        }

        return reverseLookup
    }

    func base36to16() -> String? {
        var bytes = [Int]()
        for character in self {
            guard var carry = String.base36AlphabetMap[character] else { return nil }

            for byteIndex in 0..<bytes.count {
                carry += bytes[byteIndex] * 36
                bytes[byteIndex] = carry & 0xff
                carry >>= 8
            }

            while carry > 0 {
                bytes.append(carry & 0xff)
                carry >>= 8
            }
        }

        let hexAddress = bytes.reversed().map { byte in String(format: "%02hhx", byte) }.joined()

        return hexAddress
    }
}
