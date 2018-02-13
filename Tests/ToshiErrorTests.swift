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

class ToshiErrorTests: QuickSpec {

    override func spec() {
        describe("Toshi Error") {
            context("") {

                it("initialises a toshi error from a teapot error") {
                    let teapotError = TeapotError(withType: .invalidResponseStatus, description: "Teapot error description", responseStatus: 400, underlyingError: nil)

                    let toshiError = ToshiError(withTeapotError: teapotError)
                    expect(toshiError).toNot(beNil())

                    expect(toshiError.responseStatus).to(equal(400))
                    expect(toshiError.type).to(equal(ToshiError.ErrorType.invalidResponseStatus))
                    expect(toshiError.description).to(equal("Teapot error description"))
                }

                it("gives a generic error back from an invalid teapot error type") {
                    let teapotError = TeapotError(withType: .missingMockFile, description: "Teapot error description", responseStatus: 400, underlyingError: nil)

                    let toshiError = ToshiError(withTeapotError: teapotError)

                    expect(toshiError).toNot(beNil())
                    expect(toshiError.type).to(equal(ToshiError.ErrorType.generic))
                    expect(toshiError.responseStatus).to(equal(400))
                }
            }
        }
    }
}
