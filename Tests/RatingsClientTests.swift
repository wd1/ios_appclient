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

class RatingsClientTests: QuickSpec {

    override func spec() {
        describe("the Ratings API Client") {
            var subject: RatingsClient!

            context("Happy path 😎") {

                it("submits a rating") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: RatingsClientTests.self), mockFilename: "")
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = RatingsClient(teapot: mockTeapot)

                    waitUntil { done in
                        subject.submit(userId: "testUseID", rating: 4, review: "") { success, error in
                            expect(success).to(beTrue())
                            expect(error).to(beNil())
                            
                            done()
                        }
                    }
                }

                it("fetches the score") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: RatingsClientTests.self), mockFilename: "score")
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = RatingsClient(teapot: mockTeapot)

                    waitUntil { done in
                        subject.scores(for: "testUseID") { score in
                            expect(score.reviewCount).to(equal(5))
                            expect(score.reputationScore).to(equal(2.9))
                            
                            expect(score.stars.one).to(equal(0))
                            expect(score.stars.two).to(equal(0))
                            expect(score.stars.three).to(equal(2))
                            expect(score.stars.four).to(equal(0))
                            expect(score.stars.five).to(equal(3))
                            
                            expect(score.averageRating).to(equal(4.2))
                            
                            done()
                        }
                    }
                }
            }

            context("⚠ Unauthorized 🔒") {

                it("submits a rating") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: RatingsClientTests.self), mockFilename: "", statusCode: .unauthorized)
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = RatingsClient(teapot: mockTeapot)

                    waitUntil { done in
                        subject.submit(userId: "testUseID", rating: 4, review: "") { success, error in
                            expect(success).to(beFalse())
                            expect(error).toNot(beNil())
                            
                            expect(error?.responseStatus).to(equal(401))
                            
                            done()
                        }
                    }
                }

                it("fetches the score") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: RatingsClientTests.self), mockFilename: "score", statusCode: .unauthorized)
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = RatingsClient(teapot: mockTeapot)

                    waitUntil { done in
                        subject.scores(for: "testUseID") { score in
                            expect(score.reviewCount).to(equal(0))
                            expect(score.reputationScore).to(equal(0))
                            
                            expect(score.stars.one).to(equal(0))
                            expect(score.stars.two).to(equal(0))
                            expect(score.stars.three).to(equal(0))
                            expect(score.stars.four).to(equal(0))
                            expect(score.stars.five).to(equal(0))
                            
                            expect(score.averageRating).to(equal(0))

                            done()
                        }
                    }
                }
            }
        }
    }
}
