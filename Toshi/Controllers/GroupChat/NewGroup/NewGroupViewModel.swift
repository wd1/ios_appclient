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
import UIKit

final class NewGroupViewModel {

    let filteredDatabaseViewName = "filteredDatabaseViewName"

    private var groupInfo: GroupInfo {
        didSet {
            setup()

            let oldGroupInfo = oldValue
            if oldGroupInfo.participantsIDs.count != groupInfo.participantsIDs.count {
                completeActionDelegate?.groupViewModelDidRequireReload(self)
            }
        }
    }

    private var models: [TableSectionData] = []

    init(_ groupModel: TSGroupModel) {
        groupInfo = GroupInfo()
        groupInfo.title = groupModel.nameOrEmptyString
        groupInfo.participantsIDs = groupModel.participantsIdsOrEmptyArray

        setup()
    }

    private weak var completionDelegate: GroupViewModelCompleteActionDelegate?

    private func setup() {
        let avatarTitleData = TableCellData(title: groupInfo.title, leftImage: groupInfo.avatar)
        avatarTitleData.isPlaceholder = groupInfo.title.length > 0
        avatarTitleData.tag = GroupItemType.avatarTitle.rawValue

        let avatarTitleSectionData = TableSectionData(cellsData: [avatarTitleData])

        var participantsCellData: [TableCellData] = []

        setupSortedMembers()
        for member in sortedMembers {
            participantsCellData.append(TableCellData(title: member.nameOrDisplayName, subtitle: member.displayUsername, leftImage: AvatarManager.shared.cachedAvatar(for: member.avatarPath)))
        }

        let participantsHeaderTitle = LocalizedPlural("group_participants_header_title", for: groupInfo.participantsIDs.count)
        let participantsSectionData = TableSectionData(cellsData: participantsCellData, headerTitle: participantsHeaderTitle)

        models = [avatarTitleSectionData, participantsSectionData]
    }

    private var _sortedMembers: [TokenUser] = []

    @objc private func createGroup() {
        var groupParticipantsIds = groupInfo.participantsIDs
        groupParticipantsIds.append(Cereal.shared.address)

        completeActionDelegate?.groupViewModelDidStartCreateOrUpdate()

        let image = groupInfo.avatar

        ChatInteractor.createGroup(with: NSMutableArray(array: groupParticipantsIds), name: groupInfo.title, avatar: image, completion: { [weak self] _ in

            self?.completeActionDelegate?.groupViewModelDidFinishCreateOrUpdate()
        })
    }
}

extension NewGroupViewModel: GroupViewModelProtocol {

    var completeActionDelegate: GroupViewModelCompleteActionDelegate? {
        get {
            return completionDelegate
        }
        set {
            completionDelegate = newValue
        }
    }

    var sortedMembers: [TokenUser] {
        get {
            return _sortedMembers
        }
        set {
            _sortedMembers = newValue
        }
    }

    var sectionModels: [TableSectionData] {
        return models
    }

    func updateAvatar(to image: UIImage) {
        groupInfo.avatar = image
    }

    func updateTitle(to title: String) {
        groupInfo.title = title
    }

    func updatePublicState(to isPublic: Bool) {
        groupInfo.isPublic = isPublic
    }

    func updateNotificationsState(to notificationsOn: Bool) {
        groupInfo.notificationsOn = notificationsOn
    }

    func updateRecipientsIds(to recipientsIds: [String]) {
        groupInfo.participantsIDs = recipientsIds
    }

    var groupThread: TSGroupThread? { return nil }

    var rightBarButtonSelector: Selector {
        return #selector(createGroup)
    }

    var viewControllerTitle: String { return Localized("new_group_title") }
    var rightBarButtonTitle: String { return Localized("create_group_button_title") }
    var imagePickerTitle: String { return Localized("image-picker-select-source-title") }
    var imagePickerCameraActionTitle: String { return Localized("image-picker-camera-action-title") }
    var imagePickerLibraryActionTitle: String { return Localized("image-picker-library-action-title") }
    var imagePickerCancelActionTitle: String { return Localized("cancel_action_title") }

    var errorAlertTitle: String { return Localized("error_title") }
    var errorAlertMessage: String { return Localized("toshi_generic_error") }

    var isDoneButtonEnabled: Bool { return groupInfo.title.length > 0 }

    var recipientsIds: [String] { return groupInfo.participantsIDs }
    var allParticipantsIDs: [String] { return sortedMembers.map { $0.address } }
}
