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
import XCTest
@testable import Toshi

class TextTransformerTests: XCTestCase {
    func testNoLinksOrUsernames() {
        let textColor = UIColor.red
        let linkColor = UIColor.green
        let font = UIFont.boldSystemFont(ofSize: 33)

        let text = "No links and no usernames."
        let expectedText = NSAttributedString(string: text, attributes: [.foregroundColor: textColor, .font: font, .kern: -0.4])
        let attributedText = TextTransformer.attributedUsernameString(to: text, textColor: textColor, linkColor: linkColor, font: font)!

        XCTAssert(attributedText.isEqual(to: expectedText))
    }

    func testHasLinksButNoUsernames() {
        let textColor = UIColor.red
        let linkColor = UIColor.green
        let font = UIFont.boldSystemFont(ofSize: 33)

        let text = "This link http://link.test.com and no usernames."
        let expectedText = NSAttributedString(string: text, attributes: [.foregroundColor: textColor, .font: font, .kern: -0.4])
        let attributedText = TextTransformer.attributedUsernameString(to: text, textColor: textColor, linkColor: linkColor, font: font)!

        XCTAssert(attributedText.isEqual(to: expectedText))
    }

    func testNoLinksButHasUsernames() {
        let textColor = UIColor.red
        let linkColor = UIColor.green
        let font = UIFont.boldSystemFont(ofSize: 33)
        let firstLinkAttributes: [NSAttributedStringKey: Any] = [
            .link: "toshi://username:@toshi",
            .foregroundColor: linkColor,
            .underlineStyle: NSUnderlineStyle.styleSingle.rawValue
        ]
        let secondLinkAttributes: [NSAttributedStringKey: Any] = [
            .link: "toshi://username:@tristan",
            .foregroundColor: linkColor,
            .underlineStyle: NSUnderlineStyle.styleSingle.rawValue
        ]
        let text = "Some usernames such as @toshi are highlighted even at the end of strings with cluster emoji 👨🏼‍🔬, right @tristan?"
        let expectedText = NSMutableAttributedString(string: text, attributes: [.foregroundColor: textColor, .font: font, .kern: -0.4])
        expectedText.addAttributes(secondLinkAttributes, range: (text as NSString).range(of: "@tristan"))
        expectedText.addAttributes(firstLinkAttributes, range: (text as NSString).range(of: "@toshi"))

        let attributedText = TextTransformer.attributedUsernameString(to: text, textColor: textColor, linkColor: linkColor, font: font)!

        XCTAssert(attributedText.isEqual(to: expectedText))
    }

    func testLinksAndUsernames() {
        let textColor = UIColor.red
        let linkColor = UIColor.green
        let font = UIFont.boldSystemFont(ofSize: 33)
        let firstLinkAttributes: [NSAttributedStringKey: Any] = [
            .link: "toshi://username:@toshi",
            .foregroundColor: linkColor,
            .underlineStyle: NSUnderlineStyle.styleSingle.rawValue
        ]
        let secondLinkAttributes: [NSAttributedStringKey: Any] = [
            .link: "toshi://username:@tristan",
            .foregroundColor: linkColor,
            .underlineStyle: NSUnderlineStyle.styleSingle.rawValue
        ]
        let text = "Some usernames such as @toshi are highlighted even with a https://blog.toshi.org/@username at the end of strings with cluster emoji 👨🏼‍🔬, right @tristan?"
        let expectedText = NSMutableAttributedString(string: text, attributes: [.foregroundColor: textColor, .font: font, .kern: -0.4])
        expectedText.addAttributes(secondLinkAttributes, range: (text as NSString).range(of: "@tristan"))
        expectedText.addAttributes(firstLinkAttributes, range: (text as NSString).range(of: "@toshi"))

        let attributedText = TextTransformer.attributedUsernameString(to: text, textColor: textColor, linkColor: linkColor, font: font)!

        XCTAssert(attributedText.isEqual(to: expectedText))
    }
}
