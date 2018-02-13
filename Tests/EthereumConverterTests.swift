import XCTest
import UIKit
import Quick
import Nimble
@testable import Toshi

class EthereumConverterTests: QuickSpec {

    override func spec() {
        describe("the Ethereum Converter") {
            context("exchange rate of 100.0") {
                let exchangeRate: Decimal = 100.0
                let wei: NSDecimalNumber = 1000000000000000000

                it("converts local currency to ethereum") {
                    let localFiat: NSNumber = 100.0
                    let ether = EthereumConverter.localFiatToEther(forFiat: localFiat, exchangeRate: exchangeRate)

                    expect(ether).to(equal(1.0))
                }

                it("returns the string representation of an eth value") {
                    let ethereumValueString = EthereumConverter.ethereumValueString(forEther: 3.5)

                    expect(ethereumValueString).to(equal("3.5000 ETH"))
                }

                it("returns a string representation in eht for a given wei value") {
                    let ethereumValueString = EthereumConverter.ethereumValueString(forWei: wei)

                    expect(ethereumValueString).to(equal("1.0000 ETH"))
                }

                it("returns fiat currency value string with redundant 3 letter code") {
                    let ethereumValueString = EthereumConverter.fiatValueStringWithCode(forWei: wei, exchangeRate: exchangeRate)

                    let dollarSting = String(format: "$100%@00 USD", TokenUser.current?.cachedCurrencyLocale?.decimalSeparator ?? ".")
                    expect(ethereumValueString).to(equal(dollarSting))
                }

                context("balance sparse attributed string") {
                    let fontAttribute = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 19.0)]
                    let ethereumValueString = EthereumConverter.balanceSparseAttributedString(forWei: wei, exchangeRate: exchangeRate, width: 100.0, attributes: fontAttribute)

                    let dollarSting = String(format: "$100%@00 USD", TokenUser.current?.cachedCurrencyLocale?.decimalSeparator ?? ".")
                    it("has the right values") {
                        expect(ethereumValueString.string).to(beginWith(dollarSting))
                        expect(ethereumValueString.string).to(endWith("1.0000 ETH"))
                    }

                    it("has the right attributes") {
                        let fiatAttributes = ethereumValueString.attributes(at: 0, effectiveRange: nil)
                        expect(fiatAttributes[NSAttributedStringKey.foregroundColor] as? UIColor).to(equal(Theme.darkTextColor))
                        expect(fiatAttributes[NSAttributedStringKey.font] as? UIFont).to(equal(UIFont.systemFont(ofSize: 19.0)))

                        let ethAttributes = ethereumValueString.attributes(at: ethereumValueString.string.count - 1, effectiveRange: nil)
                        expect(ethAttributes[NSAttributedStringKey.foregroundColor] as? UIColor).to(equal(Theme.greyTextColor))
                    }
                }

                context("balance attributed string") {
                    let fontAttribute = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 19.0)]
                    let ethereumValueString = EthereumConverter.balanceAttributedString(forWei: wei, exchangeRate: exchangeRate, attributes: fontAttribute)

                    let dollarSting = String(format: "$100%@00 USD", TokenUser.current?.cachedCurrencyLocale?.decimalSeparator ?? ".")
                    it("has the right values") {
                        expect(ethereumValueString.string).to(beginWith(dollarSting))
                        expect(ethereumValueString.string).to(endWith("1.0000 ETH"))
                    }

                    it("has the right attributes") {
                        let fiatAttributes = ethereumValueString.attributes(at: 0, effectiveRange: nil)
                        expect(fiatAttributes[NSAttributedStringKey.foregroundColor] as? UIColor).to(equal(Theme.darkTextColor))
                        expect(fiatAttributes[NSAttributedStringKey.font] as? UIFont).to(equal(UIFont.systemFont(ofSize: 19.0)))

                        let ethAttributes = ethereumValueString.attributes(at: ethereumValueString.string.count - 1, effectiveRange: nil)
                        expect(ethAttributes[NSAttributedStringKey.foregroundColor] as? UIColor).to(equal(Theme.greyTextColor))
                    }
                }
            }
        }
    }
}
