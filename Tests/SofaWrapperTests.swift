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

class SofaWrapperTests: QuickSpec {
    override func spec() {

        describe("initialising payment") {
            context("with fiatValueString in the content") {

                it("doesn't add a fiatValueString to String content") {
                    let sofaString = "SOFA::Payment:{\"fiatValueString\":\"$2.00 USD\",\"value\":\"0x17ac784453a3d2\"}"
                    let sofaPayment = SofaPayment(content: sofaString)

                    expect(sofaPayment.fiatValueString).to(equal("$2.00 USD"))
                }

                it("doesn't add a fiatValueString to content dictionary") {
                    let sofaDictionary: [String: Any] = [
                        "value": "0x17ac784453a3d2",
                        "fiatValueString": "$2.00 USD"
                    ]

                    let sofaPayment = SofaPayment(content: sofaDictionary)

                    expect(sofaPayment.fiatValueString).to(equal("$2.00 USD"))
                }
            }

            context("without fiatValueString in the content") {

                it("adds a fiatValueString to String content") {
                    let sofaString = "SOFA::Payment:{\"value\":\"0x17ac784453a3d2\"}"
                    let sofaPayment = SofaPayment(content: sofaString)

                    expect(sofaPayment.fiatValueString).toNot(equal(""))
                }

                it("adds a fiatValueString to content dictionary") {
                    let sofaDictionary: [String: Any] = [
                        "value": "0x17ac784453a3d2"
                    ]

                    let sofaPayment = SofaPayment(content: sofaDictionary)

                    expect(sofaPayment.fiatValueString).toNot(equal(""))
                }
            }
        }

        describe("sending payment or paymentRequest") {
            context("with fiatValueString in the content") {

                it("it removes fiatValueString from String content") {
                    let sofaString = "SOFA::Payment:{\"fiatValueString\":\"$2.00 USD\",\"value\":\"0x17ac784453a3d2\"}"
                    let payment = SofaPayment(content: sofaString)

                    payment.removeFiatValueString()

                    expect(payment.content).to(equal("SOFA::Payment:{\"value\":\"0x17ac784453a3d2\"}"))
                }
            }
        }
    }
}
