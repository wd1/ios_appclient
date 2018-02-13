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

import XCTest
import UIKit
import Quick
import Nimble
import Teapot
@testable import Toshi

class ExchangeRateAPIClientTests: QuickSpec {

    override func spec() {
        describe("the exchange rate API Client") {
            var subject: ExchangeRateAPIClient!

            context("Happy path 😎") {
                it("gets the exchange rate") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: ExchangeRateAPIClientTests.self), mockFilename: "getRate")
                    subject = ExchangeRateAPIClient(teapot: mockTeapot)

                    waitUntil { done in
                        subject.getRate { decimal in
                            expect(decimal).toNot(beNil())
                            done()
                        }
                    }
                }

                it("gets the currencies") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: ExchangeRateAPIClientTests.self), mockFilename: "getCurrencies")
                    subject = ExchangeRateAPIClient(teapot: mockTeapot, cacheEnabled: false)

                    waitUntil { done in
                        subject.getCurrencies { currencies in
                            expect(currencies.count).to(equal(3))
                            done()
                        }
                    }
                }
            }

            context("Not found") {
                it("gets the exchange rate") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: ExchangeRateAPIClientTests.self), mockFilename: "getRate", statusCode: .notFound)
                    subject = ExchangeRateAPIClient(teapot: mockTeapot)

                    waitUntil { done in
                        subject.getRate { decimal in
                            expect(decimal).to(beNil())
                            done()
                        }
                    }
                }

                it("gets the currencies") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: ExchangeRateAPIClientTests.self), mockFilename: "getCurrencies", statusCode: .notFound)
                    subject = ExchangeRateAPIClient(teapot: mockTeapot, cacheEnabled: false)

                    waitUntil { done in
                        subject.getCurrencies { currencies in
                            expect(currencies.count).to(equal(0))
                            done()
                        }
                    }
                }
            }
        }
    }
}
