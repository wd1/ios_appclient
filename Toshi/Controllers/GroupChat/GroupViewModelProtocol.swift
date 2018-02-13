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

enum GroupItemType: Int {
    case avatarTitle
    case notifications
    case isPublic
    case participant
    case addParticipant
    case exitGroup
}

struct GroupInfo {
    let placeholder = Localized("new_group_title")
    var title: String = ""
    var avatar = #imageLiteral(resourceName: "avatar-placeholder")
    var isPublic = false
    var notificationsOn = true
    var participantsIDs: [String] = []
}

protocol GroupViewModelCompleteActionDelegate: class {

    func groupViewModelDidFinishCreateOrUpdate()
    func groupViewModelDidStartCreateOrUpdate()
    func groupViewModelDidRequireReload(_ viewModel: GroupViewModelProtocol)
}

protocol GroupViewModelProtocol: class {

    var sectionModels: [TableSectionData] { get }
    var viewControllerTitle: String { get }
    var rightBarButtonTitle: String { get }
    var imagePickerTitle: String { get }
    var imagePickerCameraActionTitle: String { get }
    var imagePickerLibraryActionTitle: String { get }
    var imagePickerCancelActionTitle: String { get }

    var groupThread: TSGroupThread? { get }

    var errorAlertTitle: String { get }
    var errorAlertMessage: String { get }

    var rightBarButtonSelector: Selector { get }

    var recipientsIds: [String] { get }
    var allParticipantsIDs: [String] { get }
    var sortedMembers: [TokenUser] { get set }

    func updateAvatar(to image: UIImage)
    func updatePublicState(to isPublic: Bool)
    func updateNotificationsState(to notificationsOn: Bool)
    func updateTitle(to title: String)
    func updateRecipientsIds(to recipientsIds: [String])

    func setupSortedMembers()

    var isDoneButtonEnabled: Bool { get }

    var completeActionDelegate: GroupViewModelCompleteActionDelegate? { get set }
}

extension GroupViewModelProtocol {

    func setupSortedMembers() {

        guard let currentUser = TokenUser.current else {
            CrashlyticsLogger.log("Failed to access current user")
            fatalError("Can't access current user")
        }

        var members = SessionManager.shared.contactsManager.tokenContacts
        members.append(currentUser)
        members = members.filter { recipientsIds.contains($0.address) }

        sortedMembers = members.sorted { $0.username < $1.username }
    }
}
