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

public struct TextTransformer {
    private static var usernameDetector: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: " ?(@[a-z][a-z0-9_]{2,59}) ?", options: [.caseInsensitive, .useUnicodeWordBoundaries])
        } catch {
            fatalError("Couldn't instantiate usernameDetector, invalid pattern for regular expression")
        }
    }()

    public static func attributedUsernameString(to string: String?, textColor: UIColor, linkColor: UIColor, font: UIFont) -> NSAttributedString? {
        guard let string = string else { return nil }

        let attributedText = NSMutableAttributedString(string: string, attributes: [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: textColor])

        // string.count returns the number of rendered characters on a string
        // but NSAttributedString attributes operate on the utf16 codepoints.
        // If a string is using clusters such as emoji, the range will mismatch.
        // A visible side-effect of this miscounted string length was usernames
        // at the end of strings with emoji not being matched completely.
        let range = NSRange(location: 0, length: attributedText.string.utf16.count)
        attributedText.addAttributes([.kern: -0.4], range: range)

        // Do a link detector first-pass, to avoid creating username links inside URLs that contain an @ sign.
        let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let links = linkDetector!.matches(in: attributedText.string, options: [], range: range).reversed()

        var excludedRanges = [NSRange]()
        for link in links {
            excludedRanges.append(link.range)
        }

        // It's always good practice to traverse and modify strings from the end to the start.
        // If any of those changes affect the string length, all the subsequent ranges will be invalidated
        // causing all sort of hard to diagnose problems.
        let matches = usernameDetector.matches(in: attributedText.string, options: [], range: range).reversed()
        for match in matches {
            let matchRange = match.range(at: 1)
            // Ignore if our username regex matched inside a URL exclusion range.
            guard excludedRanges.flatMap({ r -> NSRange? in return matchRange.intersection(r) }).count == 0 else { continue }

            let attributes: [NSAttributedStringKey: Any] = [
                .link: "toshi://username:\((attributedText.string as NSString).substring(with: matchRange))",
                .foregroundColor: linkColor,
                .underlineStyle: NSUnderlineStyle.styleSingle.rawValue
            ]

            attributedText.addAttributes(attributes, range: matchRange)
        }

        return attributedText
    }
}
