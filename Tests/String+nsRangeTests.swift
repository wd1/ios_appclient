import XCTest
import UIKit
import Quick
import Nimble
@testable import Toshi

class String_nsRangeTests: QuickSpec {

    override func spec() {
        describe("String nsRange extension") {
            it("returns an NSRange from the substring of a string") {
                let string = "the whole string"
                let subString = "string"

                let nsRange = string.nsRange(forSubstring: subString)

                expect(nsRange).to(equal(NSRange(location: 10, length: 6)))
            }

            it("returns an empty NSRange from the random string") {
                let string = "the whole string"
                let randomString = "this is something else"

                let nsRange = string.nsRange(forSubstring: randomString)

                expect(nsRange).to(equal(NSRange(location: 0, length: 0)))
            }

            it("returns the entire range of the string if you take the whole string as 'substring'") {
                let string = "the whole string"
                let randomString = "the whole string"

                let nsRange = string.nsRange(forSubstring: randomString)

                expect(nsRange).to(equal(NSRange(location: 0, length: string.count)))
            }
        }
    }
}
