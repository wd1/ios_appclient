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

final class GroupInfoViewModel {

    let filteredDatabaseViewName = "filteredDatabaseViewName"

    private var thread: TSGroupThread

    private var groupInfo: GroupInfo {
        didSet {
            setup()

            let oldGroupInfo = oldValue
            if oldGroupInfo.participantsIDs.count != groupInfo.participantsIDs.count {
                completeActionDelegate?.groupViewModelDidRequireReload(self)
            }
        }
    }

    init(_ groupThread: TSGroupThread) {
        self.thread = groupThread
        let groupModel = groupThread.groupModel

        groupInfo = GroupInfo()
        groupInfo.title = groupModel.nameOrEmptyString
        groupInfo.participantsIDs = groupModel.participantsIdsOrEmptyArray
        groupInfo.avatar = groupModel.avatarOrPlaceholder

        setup()
    }

    private weak var completionDelegate: GroupViewModelCompleteActionDelegate?

    private var models: [TableSectionData] = []

    private func setup() {
        let avatarTitleData = TableCellData(title: groupInfo.title, leftImage: groupInfo.avatar)
        avatarTitleData.isPlaceholder = groupInfo.title.length > 0
        avatarTitleData.tag = GroupItemType.avatarTitle.rawValue

        let avatarTitleSectionData = TableSectionData(cellsData: [avatarTitleData])

        let participantsSectionData = setupParticipantsSection()

        let leaveGroupCellData = TableCellData(title: Localized("group_info_leave_group_title"))
        leaveGroupCellData.tag = GroupItemType.exitGroup.rawValue

        let exitGroupSectionData = TableSectionData(cellsData: [leaveGroupCellData])

        models = [avatarTitleSectionData, participantsSectionData, exitGroupSectionData]
    }

    private func setupParticipantsSection() -> TableSectionData {
        let addParticipantsData = TableCellData(title: Localized("new_group_add_participants_action_title"))
        addParticipantsData.tag = GroupItemType.addParticipant.rawValue

        var participantsCellData: [TableCellData] = [addParticipantsData]

        setupSortedMembers()
        
        for member in sortedMembers {
            let cellData = TableCellData(title: member.name, subtitle: member.displayUsername, leftImage: AvatarManager.shared.cachedAvatar(for: member.avatarPath))
            cellData.tag = GroupItemType.participant.rawValue
            participantsCellData.append(cellData)
        }

        let headerTitle = LocalizedPlural("group_participants_header_title", for: groupInfo.participantsIDs.count)
        
        return TableSectionData(cellsData: participantsCellData, headerTitle: headerTitle)
    }

    private var _sortedMembers: [TokenUser] = []

    @objc private func updateGroup() {
        let image = groupInfo.avatar
        guard let updatedGroupModel = TSGroupModel(title: groupInfo.title, memberIds: NSMutableArray(array: groupInfo.participantsIDs), image: image, groupId: thread.groupModel.groupId) else { return }

        completeActionDelegate?.groupViewModelDidStartCreateOrUpdate()

        ChatInteractor.updateGroup(with: updatedGroupModel, completion: { [weak self] _ in
            self?.completeActionDelegate?.groupViewModelDidFinishCreateOrUpdate()
        })
    }
}

extension GroupInfoViewModel: GroupViewModelProtocol {

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
    
    func updateRecipientsIds(to recipientsIds: [String]) {
        groupInfo.participantsIDs.append(contentsOf: recipientsIds)
    }

    func updatePublicState(to isPublic: Bool) {
        groupInfo.isPublic = isPublic
    }

    func updateNotificationsState(to notificationsOn: Bool) {
        groupInfo.notificationsOn = notificationsOn
    }

    var groupThread: TSGroupThread? { return thread }

    var rightBarButtonSelector: Selector { return #selector(updateGroup) }

    var viewControllerTitle: String { return Localized("group_info_title") }
    var rightBarButtonTitle: String { return Localized("update_group_button_title") }
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
