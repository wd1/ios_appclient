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

/// An individual Dapp
final class Dapp: Codable {
    
    let name: String
    let url: URL
    let avatarUrlString: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case
        name,
        url,
        avatarUrlString = "avatar",
        description
    }
}

extension Dapp: BrowseableItem {
    
    var nameForBrowseAndSearch: String {
        return name
    }
    
    var descriptionForSearch: String {
        return description
    }
    
    var avatarPath: String {
        return avatarUrlString
    }
    
    var shouldShowRating: Bool {
        return false
    }
    
    var rating: Float? {
        return nil
    }
}

typealias DappInfo = (dappURL: URL, imagePath: String?, headerText: String?)

/// Convenience class for decoding an array of Dapps with the key "results"
final class DappResults: Codable {
    
    let results: [Dapp]
    
    enum CodingKeys: String, CodingKey {
        case
        results
    }
}
