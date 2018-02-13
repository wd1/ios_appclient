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

class String_SofaHelpersTests: QuickSpec {
    override func spec() {

        describe("the SOFA related extensions on String") {
            context("none") {

                it("doesn't remove anything in case of .none") {
                    let sofaString = "SOFA::Message:{content: content}"
                    let newString = SofaWrapper.removeSofaIdentifier(from: sofaString, for: SofaType.none)

                    expect(newString).to(equal("SOFA::Message:{content: content}"))
                }

                it("doesn't add anything in case of .none") {
                    let sofaString = "{content: content}"
                    let newString = SofaWrapper.addSofaIdentifier(to: sofaString, for: SofaType.none)

                    expect(newString).to(equal("{content: content}"))
                }
            }

            context("message") {

                it("removes message sofa identifier") {
                    let sofaString = "SOFA::Message:{content: content}"
                    let newString = SofaWrapper.removeSofaIdentifier(from: sofaString, for: SofaType.message)

                    expect(newString).to(equal("{content: content}"))
                }

                it("adds message sofa identifier") {
                    let sofaString = "{content: content}"
                    let newString = SofaWrapper.addSofaIdentifier(to: sofaString, for: SofaType.message)

                    expect(newString).to(equal("SOFA::Message:{content: content}"))
                }
            }

            context("command") {

                it("removes command sofa identifier") {
                    let sofaString = "SOFA::Command:{content: content}"
                    let newString = SofaWrapper.removeSofaIdentifier(from: sofaString, for: SofaType.command)

                    expect(newString).to(equal("{content: content}"))
                }

                it("adds command sofa identifier") {
                    let sofaString = "{content: content}"
                    let newString = SofaWrapper.addSofaIdentifier(to: sofaString, for: SofaType.command)

                    expect(newString).to(equal("SOFA::Command:{content: content}"))
                }
            }

            context("initialRequest") {

                it("removes initialRequest sofa identifier") {
                    let sofaString = "SOFA::InitRequest:{content: content}"
                    let newString = SofaWrapper.removeSofaIdentifier(from: sofaString, for: SofaType.initialRequest)

                    expect(newString).to(equal("{content: content}"))
                }

                it("adds initialRequest sofa identifier") {
                    let sofaString = "{content: content}"
                    let newString = SofaWrapper.addSofaIdentifier(to: sofaString, for: SofaType.initialRequest)

                    expect(newString).to(equal("SOFA::InitRequest:{content: content}"))
                }
            }

            context("initialResponse") {

                it("removes initialResponse sofa identifier") {
                    let sofaString = "SOFA::Init:{content: content}"
                    let newString = SofaWrapper.removeSofaIdentifier(from: sofaString, for: SofaType.initialResponse)

                    expect(newString).to(equal("{content: content}"))
                }

                it("adds initialResponse sofa identifier") {
                    let sofaString = "{content: content}"
                    let newString = SofaWrapper.addSofaIdentifier(to: sofaString, for: SofaType.initialResponse)

                    expect(newString).to(equal("SOFA::Init:{content: content}"))
                }
            }

            context("paymentRequest") {

                it("removes paymentRequest sofa identifier") {
                    let sofaString = "SOFA::PaymentRequest:{content: content}"
                    let newString = SofaWrapper.removeSofaIdentifier(from: sofaString, for: SofaType.paymentRequest)

                    expect(newString).to(equal("{content: content}"))
                }

                it("adds paymentRequest sofa identifier") {
                    let sofaString = "{content: content}"
                    let newString = SofaWrapper.addSofaIdentifier(to: sofaString, for: SofaType.paymentRequest)

                    expect(newString).to(equal("SOFA::PaymentRequest:{content: content}"))
                }
            }

            context("payment") {

                it("removes payment sofa identifier") {
                    let sofaString = "SOFA::Payment:{content: content}"
                    let newString = SofaWrapper.removeSofaIdentifier(from: sofaString, for: SofaType.payment)

                    expect(newString).to(equal("{content: content}"))
                }

                it("adds payment sofa identifier") {
                    let sofaString = "{content: content}"
                    let newString = SofaWrapper.addSofaIdentifier(to: sofaString, for: SofaType.payment)

                    expect(newString).to(equal("SOFA::Payment:{content: content}"))
                }
            }
        }
    }
}
