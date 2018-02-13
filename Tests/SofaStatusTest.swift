import XCTest
import UIKit
import Quick
import Nimble
@testable import Toshi

class SofaStatusTests: QuickSpec {

    override func spec() {
        describe("Sofa status added") {
            let sofaString = "SOFA::Status:{\"type\":\"added\",\"subject\":\"Robert\",\"object\":\"Marek\"}"
            let status = SofaStatus(content: sofaString)

            it("creates a sofa status from a sofa string") {
                expect(status.statusType).to(equal(SofaStatus.StatusType.added))
                expect(status.subject).to(equal("Robert"))
                expect(status.object).to(equal("Marek"))
            }

            it("creates an attributed string with bold parts for the names") {
                guard let attributedText = status.attributedText else {
                    XCTFail("no attributed text set on sofa status")
                    return
                }

                let robertRange = attributedText.string.nsRange(forSubstring: "Robert")
                let boldAttribute = attributedText.attributes(at: robertRange.location, effectiveRange: nil)
                expect(boldAttribute[NSAttributedStringKey.font] as? UIFont).to(equal(Theme.preferredFootnoteBold()))

                let marekRange = attributedText.string.nsRange(forSubstring: "Marek")
                let boldAttribute2 = attributedText.attributes(at: marekRange.location, effectiveRange: nil)
                expect(boldAttribute2[NSAttributedStringKey.font] as? UIFont).to(equal(Theme.preferredFootnoteBold()))

                let allRange = attributedText.string.nsRange(forSubstring: "added")
                let normalAttributes = attributedText.attributes(at: allRange.location, effectiveRange: nil)
                expect(normalAttributes[NSAttributedStringKey.font] as? UIFont).to(equal(Theme.preferredFootnote()))
            }
        }

        describe("Sofa status rename") {
            let sofaString = "SOFA::Status:{\"type\":\"rename\",\"subject\":\"Robert\",\"object\":\"New group name\"}"
            let status = SofaStatus(content: sofaString)

            it("creates a sofa status from a sofa string") {
                expect(status.statusType).to(equal(SofaStatus.StatusType.rename))
                expect(status.subject).to(equal("Robert"))
                expect(status.object).to(equal("New group name"))
            }

            it("creates an attributed string with bold parts for the name and the new group name") {
                guard let attributedText = status.attributedText else {
                    XCTFail("no attributed text set on sofa status")
                    return
                }

                let robertRange = attributedText.string.nsRange(forSubstring: "Robert")
                let boldAttribute = attributedText.attributes(at: robertRange.location, effectiveRange: nil)
                expect(boldAttribute[NSAttributedStringKey.font] as? UIFont).to(equal(Theme.preferredFootnoteBold()))

                let marekRange = attributedText.string.nsRange(forSubstring: "New group name")
                let boldAttribute2 = attributedText.attributes(at: marekRange.location, effectiveRange: nil)
                expect(boldAttribute2[NSAttributedStringKey.font] as? UIFont).to(equal(Theme.preferredFootnoteBold()))

                let allRange = attributedText.string.nsRange(forSubstring: "renamed the group to")
                let normalAttributes = attributedText.attributes(at: allRange.location, effectiveRange: nil)
                expect(normalAttributes[NSAttributedStringKey.font] as? UIFont).to(equal(Theme.preferredFootnote()))
            }
        }
    }
}
