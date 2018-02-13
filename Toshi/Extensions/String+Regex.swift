import Foundation

extension String {

    var hasAddressPrefix: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).starts(with: "0x")
    }

    func firstMatch(pattern: String) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.length))
    }
}
