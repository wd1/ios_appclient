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

import UIKit
import SweetSwift

struct EthereumConverter {

    /// The conversion rate between wei and eth. Each eth is made up of 1 x 10^18 wei.
    private static let weisToEtherConstant = NSDecimalNumber(string: "1000000000000000000")

    /// Each eth is made up of 1 x 10^18 wei.
    static var weisToEtherPowerOf10Constant: Int16 {
        return Int16(18)
    }

    /// Converts local currency to ethereum. Currently only supports USD.
    ///
    /// - Parameter balance: the value in USD to be converted to eth.
    /// - Returns: the eth value.
    static func localFiatToEther(forFiat balance: NSNumber, exchangeRate: Decimal) -> NSDecimalNumber {
        let etherValue = balance.decimalValue / exchangeRate

        return NSDecimalNumber(decimal: etherValue).rounding(accordingToBehavior: NSDecimalNumber.weiRoundingBehavior)
    }

    /// Returns the string representation of an eth value.
    /// Example: "9.2 ETH"
    ///
    /// - Parameter balance: the value in eth
    /// - Returns: the string representation
    static func ethereumValueString(forEther balance: NSDecimalNumber) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 4
        numberFormatter.maximumFractionDigits = 4

        return "\(numberFormatter.string(from: balance)!) ETH"
    }

    /// String representation in eht for a given wei value.
    /// Example:
    ///     ethereumValueString(forWei: halfEthInWei) -> "0.5 ETH"
    ///
    /// - Parameter balance: the wei value to be converted
    /// - Returns: the eth value in a string: "0.5 EHT"
    static func ethereumValueString(forWei balance: NSDecimalNumber) -> String {
        return ethereumValueString(forEther: balance.dividing(by: weisToEtherConstant).rounding(accordingToBehavior: NSDecimalNumber.weiRoundingBehavior))
    }

    /// The fiat currency string representation for a given wei value
    ///
    /// - Parameter balance: value in wei
    /// - Returns: fiat string representation: "$10.50"
    static func fiatValueString(forWei balance: NSDecimalNumber, exchangeRate: Decimal) -> String {
        let ether = balance.dividing(by: weisToEtherConstant)
        let currentFiatConversion = NSDecimalNumber(decimal: exchangeRate)
        let fiat: NSDecimalNumber = ether.multiplying(by: currentFiatConversion)

        let locale = TokenUser.current?.cachedCurrencyLocale ?? Currency.forcedLocale
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = locale
        numberFormatter.currencyCode = TokenUser.current?.localCurrency

        return "\(numberFormatter.string(from: fiat)!)"
    }

    /// Fiat currency value string with redundant 3 letter code. "$4.99 USD"
    ///
    /// - Parameter balance: the value in wei
    /// - Returns: the fiat currency value with redundant 3 letter code for clarity.
    static func fiatValueStringWithCode(forWei balance: NSDecimalNumber, exchangeRate: Decimal) -> String {
        let locale = TokenUser.current?.cachedCurrencyLocale ?? Currency.forcedLocale
        let localCurrency = TokenUser.current?.localCurrency ?? Currency.forcedLocale.currencyCode

        let ether = balance.dividing(by: weisToEtherConstant)
        let currentFiatConversion = NSDecimalNumber(decimal: exchangeRate)
        let fiat: NSDecimalNumber = ether.multiplying(by: currentFiatConversion)

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = locale
        numberFormatter.currencyCode = localCurrency

        let fiatValueString = numberFormatter.string(from: fiat) ?? ""

        return numberFormatter.currencySymbol == numberFormatter.currencyCode ? fiatValueString : fiatValueString + " " + localCurrency!
    }

    /// Complete formatted string value for a given wei, with fiat aligned left and eth aligned right.
    ///    "$4.99 USD                        0.0050 ETH"
    ///    Fiat is black, and eth value is light grey.
    ///
    /// - Parameters:
    ///   - balance: the value in wei
    ///   - width: the width of the label, to adjust alignment.
    ///   - attributes: the attributes of the label, to copy them on the attributed string.
    /// - Returns: the attributed string to be displayed.
    static func balanceSparseAttributedString(forWei balance: NSDecimalNumber, exchangeRate: Decimal, width: CGFloat, attributes: [NSAttributedStringKey: Any]? = nil) -> NSAttributedString {
        let attributedString = balanceAttributedString(forWei: balance, exchangeRate: exchangeRate, attributes: attributes)
        guard let mutableAttributedString = attributedString.mutableCopy() as? NSMutableAttributedString else { return attributedString }

        let range = NSRange(location: 0, length: mutableAttributedString.length)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        let nextTabStop = NSTextTab(textAlignment: .right, location: width, options: [:])
        paragraph.tabStops = [nextTabStop]
        mutableAttributedString.addAttribute(.paragraphStyle, value: paragraph, range: range)

        return mutableAttributedString
    }

    /// Complete formatted string value for a given wei, fully left aligned.
    ///    "$4.99 USD    0.0050 ETH"
    ///    Fiat is black, and eth value is light grey.
    ///
    /// - Parameters:
    ///   - balance: the value in wei
    ///   - attributes: the attributes of the label, to copy them on the attributed string.
    /// - Returns: the attributed string to be displayed.
    static func balanceAttributedString(forWei balance: NSDecimalNumber, exchangeRate: Decimal, attributes: [NSAttributedStringKey: Any]? = nil) -> NSAttributedString {

        let fiatText = fiatValueStringWithCode(forWei: balance, exchangeRate: exchangeRate)
        let etherText = ethereumValueString(forWei: balance)
        
        let fiatTextFull = fiatText + "\t"
        let text = fiatTextFull + etherText
        let etherRange = (text as NSString).range(of: etherText)
        let fiatRange = (text as NSString).range(of: fiatTextFull)

        let attributedString = NSMutableAttributedString(string: text, attributes: attributes ?? [.font: Theme.medium(size: 15)])
        attributedString.addAttribute(.foregroundColor, value: Theme.greyTextColor, range: etherRange)
        attributedString.addAttribute(.foregroundColor, value: Theme.darkTextColor, range: fiatRange)

        return attributedString
    }
}
