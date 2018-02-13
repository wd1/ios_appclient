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

import Foundation
import AwesomeCache
import Teapot
import UIKit

typealias TokenUserResults = (_ apps: [TokenUser]?, _ error: ToshiError?) -> Void

class AppsAPIClient: NSObject, CacheExpiryDefault {
    static let shared: AppsAPIClient = AppsAPIClient()

    private let topRatedAppsCachedDataKey = "topRatedAppsCachedData"
    private let featuredAppsCachedDataKey = "featuredAppsCachedData"

    private let topRatedAppsCachedData = TokenUsersCacheData()
    private let featuredAppsCachedData = TokenUsersCacheData()

    private var teapot: Teapot

    override init() {
        teapot = Teapot(baseURL: URL(string: ToshiIdServiceBaseURLPath)!)
    }

    convenience init(teapot: Teapot, cacheEnabled: Bool = true) {
        self.init()
        self.teapot = teapot

        if !cacheEnabled {
            self.cache.removeAllObjects()
        }
    }

    private lazy var cache: Cache<TokenUsersCacheData> = {
        do {
            return try Cache<TokenUsersCacheData>(name: "appsCache")
        } catch {
            fatalError("Couldn't instantiate the apps cache")
        }
    }()

    func getTopRatedApps(limit: Int = 10, completion: @escaping TokenUserResults) {
        if let data = cache.object(forKey: topRatedAppsCachedDataKey), let ratedUsers = data.objects {
            completion(ratedUsers, nil)
        }

        teapot.get("/v1/search/apps?top=true&recent=false&limit=\(limit)") { [weak self] (result: NetworkResult) in
            var resultsError: ToshiError?
            var results: [TokenUser] = []
            switch result {
            case .success(let json, _):
                guard let strongSelf = self, let json = json?.dictionary, let appsJSON = json["results"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        completion(nil, .invalidResponseJSON)
                    }
                    return
                }

                let apps = appsJSON.map { json -> TokenUser in
                    TokenUser(json: json)
                }

                apps.forEach { AvatarManager.shared.downloadAvatar(for: $0.avatarPath) }

                strongSelf.topRatedAppsCachedData.objects = apps
                strongSelf.cache.setObject(strongSelf.topRatedAppsCachedData, forKey: strongSelf.topRatedAppsCachedDataKey)

                results = apps
            case .failure(_, _, let error):
                resultsError = ToshiError(withTeapotError: error)
            }

            DispatchQueue.main.async {
                completion(results, resultsError)
            }
        }
    }

    func getFeaturedApps(limit: Int = 10, completion: @escaping TokenUserResults) {

        if let data = cache.object(forKey: featuredAppsCachedDataKey), let ratedUsers = data.objects {
            completion(ratedUsers, nil)
        }

        teapot.get("/v1/search/apps?top=false&recent=true&limit=\(limit)") { [weak self] (result: NetworkResult) in
            var resultsError: ToshiError?
            var results: [TokenUser] = []

            switch result {
            case .success(let json, _):
                guard let strongSelf = self, let json = json?.dictionary, let appsJSON = json["results"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        completion(nil, .invalidResponseJSON)
                    }
                    return
                }

                let apps = appsJSON.map { json in
                    TokenUser(json: json)
                }

                apps.forEach { AvatarManager.shared.downloadAvatar(for: $0.avatarPath) }

                strongSelf.featuredAppsCachedData.objects = apps
                strongSelf.cache.setObject(strongSelf.featuredAppsCachedData, forKey: strongSelf.featuredAppsCachedDataKey)

                results = apps
            case .failure(_, _, let error):
                resultsError = ToshiError(withTeapotError: error)
            }

            DispatchQueue.main.async {
                completion(results, resultsError)
            }
        }
    }
}
