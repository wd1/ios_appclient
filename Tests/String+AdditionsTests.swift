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

@testable import Toshi
import XCTest

class StringAdditionsTests: XCTestCase {
    
    func testEnteringAValidPrefixDoesntCreateAPossibleURL() {
        XCTAssertNil("h".asPossibleURLString)
        XCTAssertNil("ht".asPossibleURLString)
        XCTAssertNil("htt".asPossibleURLString)
        XCTAssertNil("http".asPossibleURLString)
        
        XCTAssertNil("http:".asPossibleURLString)
        XCTAssertNil("http:/".asPossibleURLString)
        XCTAssertNil("http://".asPossibleURLString)
        XCTAssertEqual("http://a".asPossibleURLString, "http://a")

        XCTAssertNil("https".asPossibleURLString)
        XCTAssertNil("https:".asPossibleURLString)
        XCTAssertNil("https:/".asPossibleURLString)
        XCTAssertNil("https://".asPossibleURLString)
        XCTAssertEqual("https://a".asPossibleURLString, "https://a")

        XCTAssertNil("f".asPossibleURLString)
        XCTAssertNil("ft".asPossibleURLString)
        XCTAssertNil("ftp".asPossibleURLString)
        XCTAssertNil("ftp:".asPossibleURLString)
        XCTAssertNil("ftp:/".asPossibleURLString)
        XCTAssertNil("ftp://".asPossibleURLString)
        XCTAssertEqual("ftp://a".asPossibleURLString, "ftp://a")
        
        XCTAssertNil("fo".asPossibleURLString)
        XCTAssertNil("foo".asPossibleURLString)
        XCTAssertNil("foo:".asPossibleURLString)
        XCTAssertNil("foo:/".asPossibleURLString)
        XCTAssertNil("foo://".asPossibleURLString)
        XCTAssertEqual("foo://a".asPossibleURLString, "foo://a")
    }
    
    func testAddingSomethingWithADotAndOneExtraCharacterCreatesPossibleURLString() {
        XCTAssertNil("foo".asPossibleURLString)
        XCTAssertNil("foo.".asPossibleURLString)
        XCTAssertEqual("foo.b".asPossibleURLString, "http://foo.b")
    }
    
    func testCaseCorrectionInPossibleURLStrings() {
        XCTAssertEqual("foo.bar".asPossibleURLString, "http://foo.bar")
        XCTAssertEqual("Foo.bar".asPossibleURLString, "http://foo.bar")
        XCTAssertEqual("FOO.BAR".asPossibleURLString, "http://foo.bar")
    }
    
    func testDescribesValueLargerThanZero() {
        XCTAssertTrue("1.00".isValidPaymentValue())
        XCTAssertTrue("1,00".isValidPaymentValue())
        XCTAssertTrue("0.10".isValidPaymentValue())
        XCTAssertTrue("0,10".isValidPaymentValue())
        XCTAssertFalse("0.00".isValidPaymentValue())
        XCTAssertFalse("0,00".isValidPaymentValue())
        XCTAssertFalse("-1.00".isValidPaymentValue())
        XCTAssertFalse("-1,00".isValidPaymentValue())
        XCTAssertFalse("hi".isValidPaymentValue())
    }

    func testSplittingStringIntoLines() {
        let shortString = "foo"

        let splitShort = shortString.toLines(count: 3)

        XCTAssertEqual(splitShort, """
f
o
o
""")

        let mediumString = "HelloThereEllen"
        let evenSplitMedium = mediumString.toLines(count: 3)
        XCTAssertEqual(evenSplitMedium, """
Hello
There
Ellen
""")
        let unevenSplitMedium = mediumString.toLines(count: 2)
        XCTAssertEqual(unevenSplitMedium, """
HelloThe
reEllen
""")
        let unevenerSplitMedium = mediumString.toLines(count: 4)
        XCTAssertEqual(unevenerSplitMedium, """
Hell
oThe
reEl
len
""")
        let unevenSupersplitMedium = mediumString.toLines(count: 7)
        XCTAssertEqual(unevenSupersplitMedium, """
He
ll
oT
he
re
El
len
""")

    }
}
