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

import UIKit

extension TSGroupModel {

    // true if all data required to display the group is loaded, false if not.
    var isFullyLoaded: Bool {
        guard let membersIds = groupMemberIds else {
            return false
        }

        guard
            membersIds.count > 1, // There must be more than just the current user as a member of the group
            groupName != nil, // There must be a name
            groupImage != nil else { // Image must either be a real image or a placeholder
                return false
        }
        
        return true
    }

    var avatarOrPlaceholder: UIImage {
        return groupImage ?? #imageLiteral(resourceName: "avatar-placeholder")
    }

    var nameOrEmptyString: String {
        return groupName ?? ""
    }

    var participantsIdsOrEmptyArray: [String] {
        return groupMemberIds ?? []
    }
}
