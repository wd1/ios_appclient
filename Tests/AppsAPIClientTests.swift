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

class AppsAPIClientTests: QuickSpec {
    override func spec() {
        describe("the Apps API Client") {
            var subject: AppsAPIClient!

            context("Happy path 😎") {

                it("fetches the top rated apps") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: AppsAPIClientTests.self), mockFilename: "getTopRatedApps")
                    subject = AppsAPIClient(teapot: mockTeapot, cacheEnabled: false)

                    waitUntil { done in
                        subject.getTopRatedApps { users, error in
                            expect(users).toNot(beNil())
                            expect(error).to(beNil())

                            guard let app = users?.first else {
                                fail("No user found!")
                                done()
                                
                                return
                            }
                            
                            expect(app.about).to(equal("The toppest of all the apps"))
                            expect(app.avatarPath).to(equal("https://token-id-service-development.herokuapp.com/avatar/0x8f9bdb7f562ccdedf3c24cf25e9cece9df62138b.png"))
                            expect(app.averageRating).to(equal(1.0))
                            expect(app.isApp).to(equal(true))
                            expect(app.location).to(equal("teh internets"))
                            expect(app.name).to(equal("Test Name"))
                            expect(app.paymentAddress).to(equal("0x011c6dd9565b8b83e6a9ee3f06e89ece3251ef2f"))
                            expect(app.isPublic).to(equal(false))
                            expect(app.reputationScore).to(equal(2.7))
                            expect(app.address).to(equal("0x8f9bdb7f562ccdedf3c24cf25e9cece9df62138b"))
                            expect(app.username).to(equal("testUsername"))
                        
                            done()
                        }
                    }
                }

                it("fetches the featured apps") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: AppsAPIClientTests.self), mockFilename: "getFeaturedApps")
                    subject = AppsAPIClient(teapot: mockTeapot, cacheEnabled: false)

                    waitUntil { done in
                        subject.getFeaturedApps { users, error in
                            expect(users).toNot(beNil())
                            expect(error).to(beNil())
                            
                            guard let app = users?.first else {
                                fail("No user found!")
                                done()
                                return
                            }
                            expect(app.about).to(equal("It's all about tests"))
                            expect(app.avatarPath).to(equal("https://token-id-service-development.herokuapp.com/avatar/0x8f9bdb7f562ccdedf3c24cf25e9cece9df62138b.png"))
                            expect(app.averageRating).to(equal(4.5))
                            expect(app.isApp).to(equal(true))
                            expect(app.location).to(equal("Hamsterdam"))
                            expect(app.name).to(equal("Moar Tests"))
                            expect(app.paymentAddress).to(equal("0x011c6dd9565b8b83e6a9ee3f06e89ece3251ef2f"))
                            expect(app.isPublic).to(equal(true))
                            expect(app.reputationScore).to(equal(5.0))
                            expect(app.address).to(equal("0x8f9bdb7f562ccdedf3c24cf25e9cece9df62138b"))
                            expect(app.username).to(equal("testUsername2"))
                            
                            done()
                        }
                    }
                }
            }

            context("⚠ Unauthorized error 🔒") {
                it("fetches the top rated apps") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: AppsAPIClientTests.self), mockFilename: "getTopRatedApps", statusCode: .unauthorized)
                    subject = AppsAPIClient(teapot: mockTeapot, cacheEnabled: false)

                    waitUntil { done in
                        subject.getTopRatedApps { users, error in
                            expect(users).toNot(beNil())
                            expect(error).toNot(beNil())
                            
                            expect(users?.count).to(equal(0))
                            expect(error?.type).to(equal(.invalidResponseStatus))
                            done()
                        }
                    }
                }

                it("fetches the featured apps") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: AppsAPIClientTests.self), mockFilename: "getFeaturedApps", statusCode: .unauthorized)
                    subject = AppsAPIClient(teapot: mockTeapot, cacheEnabled: false)

                    waitUntil { done in
                        subject.getFeaturedApps { users, error in
                            expect(error).toNot(beNil())
                            expect(users).toNot(beNil())
                            
                            expect(users?.count).to(equal(0))
                            expect(error?.type).to(equal(.invalidResponseStatus))
                            done()
                        }
                    }
                }
            }

            context("⚠ Not found error 🕳") {

                it("fetches the top rated apps") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: AppsAPIClientTests.self), mockFilename: "getTopRatedApps", statusCode: .notFound)
                    subject = AppsAPIClient(teapot: mockTeapot, cacheEnabled: false)

                    waitUntil { done in
                        subject.getTopRatedApps { users, error in
                            expect(users).toNot(beNil())
                            expect(error).toNot(beNil())
                            
                            expect(users?.count).to(equal(0))
                            expect(error?.type).to(equal(.invalidResponseStatus))
                            done()
                        }
                    }
                }

                it("fetches the featured apps") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: AppsAPIClientTests.self), mockFilename: "getFeaturedApps", statusCode: .notFound)
                    subject = AppsAPIClient(teapot: mockTeapot, cacheEnabled: false)

                    waitUntil { done in
                        subject.getFeaturedApps { users, error in
                            expect(error).toNot(beNil())
                            expect(users).toNot(beNil())
                            
                            expect(users?.count).to(equal(0))
                            expect(error?.type).to(equal(.invalidResponseStatus))
                            done()
                        }
                    }
                }
            }

            context("Invalid JSON") {

                it("fetches the top rated apps") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: AppsAPIClientTests.self), mockFilename: "score")
                    subject = AppsAPIClient(teapot: mockTeapot, cacheEnabled: false)

                    waitUntil { done in
                        subject.getTopRatedApps { users, error in
                            expect(users).to(beNil())
                            expect(error).toNot(beNil())
                            
                            expect(error?.type).to(equal(.invalidResponseJSON))

                            done()
                        }
                    }
                }

                it("fetches the featured apps") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: AppsAPIClientTests.self), mockFilename: "score")
                    subject = AppsAPIClient(teapot: mockTeapot, cacheEnabled: false)

                    waitUntil { done in
                        subject.getFeaturedApps { users, error in
                            //TODO: Do we actually want this inconsistent behavior where only on parsing errors is `users` array nil instead of empty?
                            expect(users).to(beNil())
                            expect(error).toNot(beNil())

                            expect(error?.type).to(equal(.invalidResponseJSON))
                            done()
                        }
                    }
                }
            }
        }
    }
}
