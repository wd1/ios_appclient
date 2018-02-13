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

enum ThreadsContentSection: Int {
    case unacceptedThreads
    case acceptedThreads

    var title: String? {
        switch self {
        case .acceptedThreads:
            return Localized("recent_messages_section_header_title")
        default:
            return nil
        }
    }
}

enum ThreadsDataSourceTarget {
    case recent
    case unacceptedThreadRequests

    var title: String {
        switch self {
        case .recent:
            return Localized("tab_bar_title_recent")
        case .unacceptedThreadRequests:
            return Localized("messages_requests_title")
        }
    }

    func title(for section: Int) -> String? {
        guard self == .recent, let contentSection = ThreadsContentSection(rawValue: section) else { return nil }

        switch contentSection {
        case .acceptedThreads:
            return Localized("recent_messages_section_header_title")
        default:
            return nil
        }
    }
}

protocol ThreadsDataSourceOutput: class {
    func threadsDataSourceDidLoad()
}

final class ThreadsDataSource: NSObject {

    private var viewModel: RecentViewModel
    private var target: ThreadsDataSourceTarget

    var hasUnacceptedThreads: Bool {
        return unacceptedThreadsCount > 0
    }

    var unacceptedThreadsCount: Int {
        return Int(viewModel.unacceptedThreadsMappings.numberOfItems(inSection: UInt(0)))
    }

    var acceptedThreadsCount: Int {
        return Int(viewModel.acceptedThreadsMappings.numberOfItems(inSection: UInt(0)))
    }

    var title: String {
        return target.title
    }

    weak var output: ThreadsDataSourceOutput?

    init(target: ThreadsDataSourceTarget) {
        viewModel = RecentViewModel()
        self.target = target

        super.init()

        if TokenUser.current != nil {
            viewModel.setupForCurrentSession()
            loadMessages()
            registerNotifications()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(chatDBCreated(_:)), name: .ChatDatabaseCreated, object: nil)
        }
    }

    @objc private func chatDBCreated(_ notification: Notification) {
        viewModel.setupForCurrentSession()
        loadMessages()
        registerNotifications()
    }

    @objc func yapDatabaseDidChange(notification _: NSNotification) {
        let notifications = viewModel.uiDatabaseConnection.beginLongLivedReadTransaction()

        // If changes do not affect current view, update and return without updating collection view
        // swiftlint:disable:next force_cast
        let threadViewConnection = viewModel.uiDatabaseConnection.ext(TSThreadDatabaseViewExtensionName) as! YapDatabaseViewConnection

        let hasChangesForCurrentView = threadViewConnection.hasChanges(for: notifications)
        guard hasChangesForCurrentView else {
            viewModel.uiDatabaseConnection.read { [weak self] transaction in
                self?.viewModel.acceptedThreadsMappings.update(with: transaction)
                self?.viewModel.unacceptedThreadsMappings.update(with: transaction)
                self?.viewModel.allThreadsMappings.update(with: transaction)
            }

            return
        }

        let yapDatabaseChanges = threadViewConnection.getChangesFor(notifications: notifications, with: viewModel.allThreadsMappings)
        let isDatabaseChanged = yapDatabaseChanges.rowChanges.count != 0 || yapDatabaseChanges.sectionChanges.count != 0

        guard isDatabaseChanged else { return }
        
        if let insertedRow = yapDatabaseChanges.rowChanges.first(where: { $0.type == .insert }) {

            if let newIndexPath = insertedRow.newIndexPath {
                processNewThread(at: newIndexPath)
            }
        } else if let updatedRow = yapDatabaseChanges.rowChanges.first(where: { $0.type == .update }) {

            if let indexPath = updatedRow.indexPath {
                processUpdateThread(at: indexPath)
            }
        }

        loadMessages()
        output?.threadsDataSourceDidLoad()
    }
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
    }

    func unacceptedThread(at indexPath: IndexPath) -> TSThread? {
        var thread: TSThread?

        viewModel.uiDatabaseConnection.read { [weak self] transaction in
            guard let strongSelf = self else { return }
            guard let dbExtension = transaction.extension(RecentViewModel.unacceptedThreadsFilteringKey) as? YapDatabaseViewTransaction else { return }
            guard let object = dbExtension.object(at: indexPath, with: strongSelf.viewModel.unacceptedThreadsMappings) as? TSThread else { return }

            thread = object
        }

        return thread
    }

    func thread(withAddress address: String) -> TSThread? {
        var thread: TSThread?

        viewModel.uiDatabaseConnection.read { transaction in
            transaction.enumerateRows(inCollection: TSThread.collection()) { _, object, _, stop in
                if let possibleThread = object as? TSThread {
                    if possibleThread.contactIdentifier() == address {
                        thread = possibleThread
                        stop.pointee = true
                    }
                }
            }
        }

        return thread
    }

    func thread(withIdentifier identifier: String) -> TSThread? {
        var thread: TSThread?

       viewModel.uiDatabaseConnection.read { transaction in
            transaction.enumerateRows(inCollection: TSThread.collection()) { _, object, _, stop in
                if let possibleThread = object as? TSThread {
                    if possibleThread.uniqueId == identifier {
                        thread = possibleThread
                        stop.pointee = true
                    }
                }
            }
        }

        return thread
    }

    func acceptedThread(at index: Int, in section: Int) -> TSThread? {
        var thread: TSThread?

        viewModel.uiDatabaseConnection.read { [weak self] transaction in
            guard let strongSelf = self else { return }
            guard let dbExtension = transaction.extension(RecentViewModel.acceptedThreadsFilteringKey) as? YapDatabaseViewTransaction else { return }
            let translatedIndexPath = IndexPath(row: index, section: section)
            guard let object = dbExtension.object(at: translatedIndexPath, with: strongSelf.viewModel.acceptedThreadsMappings) as? TSThread else { return }

            thread = object
        }

        return thread
    }

    func processNewThread(at indexPath: IndexPath) {
        if let thread = self.thread(at: indexPath) {
            updateNewThreadRecepientsIfNeeded(thread)
        }
    }

    func thread(at indexPath: IndexPath) -> TSThread? {
        var thread: TSThread?

         viewModel.uiDatabaseConnection.read { transaction in
            guard let dbExtension = transaction.extension(TSThreadDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { return }
            guard let object = dbExtension.object(at: indexPath, with: self.viewModel.allThreadsMappings) as? TSThread else { return }

            thread = object
        }

        return thread
    }

    func updateNewThreadRecepientsIfNeeded(_ thread: TSThread) {
        DispatchQueue.main.async {
            if let contactId = thread.contactIdentifier() {
                guard SessionManager.shared.contactsManager.tokenContact(forAddress: contactId) == nil else { return }

                let contactsIds = SessionManager.shared.contactsManager.tokenContacts.map { $0.address }

                IDAPIClient.shared.findContact(name: contactId, completion: { foundUser in

                    guard let user = foundUser else { return }

                    AvatarManager.shared.downloadAvatar(for: user.avatarPath)

                    if !contactsIds.contains(contactId) {
                        IDAPIClient.shared.updateContact(with: contactId)
                        TSThread.saveRecipient(with: contactId)
                    }
                })
            } else {
                thread.updateGroupMembers()
            }
        }
    }
    
    private func processUpdateThread(at indexPath: IndexPath) {
        if let thread = self.acceptedThread(at: indexPath.row, in: 0) {

            if let topChatViewController = Navigator.topViewController as? ChatViewController {
                topChatViewController.updateThread(thread)
            }

            if thread.isGroupThread() && ProfileManager.shared().isThread(inProfileWhitelist: thread) == false {
                ProfileManager.shared().addThread(toProfileWhitelist: thread)
            }

            thread.updateGroupMembers()
        }

        if let unacceptedThread = self.unacceptedThread(at: indexPath) {

            if let topChatViewController = Navigator.topViewController as? ChatViewController {
                topChatViewController.updateThread(unacceptedThread)
            }

            unacceptedThread.updateGroupMembers()
        }
    }

    private func loadMessages() {
        viewModel.uiDatabaseConnection.asyncRead { [weak self] transaction in
            self?.viewModel.acceptedThreadsMappings.update(with: transaction)
            self?.viewModel.unacceptedThreadsMappings.update(with: transaction)

            DispatchQueue.main.async {
                self?.output?.threadsDataSourceDidLoad()
            }
        }
    }
}
