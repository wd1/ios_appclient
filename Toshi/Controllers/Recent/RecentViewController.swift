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
import SweetFoundation
import SweetUIKit

final class RecentViewController: SweetTableController, Emptiable {

    private lazy var dataSource: ThreadsDataSource = {
        let dataSource = ThreadsDataSource(target: .recent)
        dataSource.output = self

        return dataSource
    }()

    let emptyView = EmptyView(title: Localized("chats_empty_title"), description: Localized("chats_empty_description"), buttonTitle: Localized("invite_friends_action_title"))

    private var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    let idAPIClient = IDAPIClient.shared

    override init(style: UITableViewStyle) {
        super.init(style: style)

        title = dataSource.title

        loadViewIfNeeded()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addSubviewsAndConstraints()

        tableView.delegate = self
        tableView.dataSource = self

        BasicTableViewCell.register(in: tableView)

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.showsVerticalScrollIndicator = true
        tableView.alwaysBounceVertical = true

        emptyView.isHidden = true

        dataSource.output = self
    }

    @objc func emptyViewButtonPressed(_ button: ActionButton) {
        shareWithSystemSheet(item: Localized("share_copy"))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(true)
        tabBarController?.tabBar.isHidden = false

        tableView.reloadData()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didPressCompose(_:)))
    }
    
    @objc private func didPressCompose(_ barButtonItem: UIBarButtonItem) {
        let datasource = ProfilesDataSource(type: .newChat)
        let profilesViewController = ProfilesNavigationController(rootViewController: ProfilesViewController(datasource: datasource, output: self))
        Navigator.presentModally(profilesViewController)
    }

    private func addSubviewsAndConstraints() {
        let tableHeaderHeight = navigationController?.navigationBar.frame.height ?? 0
        
        view.addSubview(emptyView)
        emptyView.actionButton.addTarget(self, action: #selector(emptyViewButtonPressed(_:)), for: .touchUpInside)
        emptyView.edges(to: layoutGuide(), insets: UIEdgeInsets(top: tableHeaderHeight, left: 0, bottom: 0, right: 0))
    }

    private func showEmptyStateIfNeeded() {
        let numberOfUnacceptedThreads = dataSource.unacceptedThreadsCount
        let numberOfAcceptedThreads = dataSource.acceptedThreadsCount
        let shouldHideEmptyState = (numberOfUnacceptedThreads + numberOfAcceptedThreads) > 0

        emptyView.isHidden = shouldHideEmptyState
    }

    private func messagesRequestsCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let firstUnacceptedThread = dataSource.unacceptedThread(at: IndexPath(row: 0, section: 0)) else {
            return UITableViewCell(frame: .zero)
        }
        
        let cellConfigurator = CellConfigurator()
        var cellData: TableCellData
        var accessoryType: UITableViewCellAccessoryType

        let requestsTitle = Localized("messages_requests_title")
        let requestsSubtitle = LocalizedPlural("message_requests_description", for: dataSource.unacceptedThreadsCount)
        let firstImage = firstUnacceptedThread.avatar()

        if let secondUnacceptedThread = dataSource.unacceptedThread(at: IndexPath(row: 1, section: 0)) {
            let secondImage = secondUnacceptedThread.avatar()
            cellData = TableCellData(title: requestsTitle, subtitle: requestsSubtitle, doubleImage: (firstImage: firstImage, secondImage: secondImage))
            accessoryType = .disclosureIndicator
        } else {
            cellData = TableCellData(title: requestsTitle, subtitle: requestsSubtitle, leftImage: firstImage)
            accessoryType = .none
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: cellConfigurator.cellIdentifier(for: cellData.components), for: indexPath)
        cellConfigurator.configureCell(cell, with: cellData)
        cell.accessoryType = accessoryType

        return cell
    }

    private func showThread(at indexPath: IndexPath) {
        guard let thread = dataSource.acceptedThread(at: indexPath.row, in: 0) else { return }
        let chatViewController = ChatViewController(thread: thread)
        navigationController?.pushViewController(chatViewController, animated: true)
    }

    func updateContactIfNeeded(at indexPath: IndexPath) {
        if let thread = dataSource.acceptedThread(at: indexPath.row, in: 0), let address = thread.contactIdentifier() {
            DLog("Updating contact info for address: \(address).")

            idAPIClient.retrieveUser(username: address) { contact in
                if let contact = contact {
                    DLog("Updated contact info for \(contact.username)")
                }
            }
        }
    }

    func thread(withAddress address: String) -> TSThread? {
        return dataSource.thread(withAddress: address)
    }

    func thread(withIdentifier identifier: String) -> TSThread? {
        return dataSource.thread(withIdentifier: identifier)
    }
}

// MARK: - Mix-in extensions

extension RecentViewController: SystemSharing { /* mix-in */ }

// MARK: - Table View Data Source

extension RecentViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if dataSource.hasUnacceptedThreads {
            return 2
        }
        
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let isUnacceptedThreadsSection = (section == 0 && dataSource.hasUnacceptedThreads)

        if isUnacceptedThreadsSection || dataSource.acceptedThreadsCount == 0 {
            return nil
        }

        return Localized("recent_messages_section_header_title")
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {

        var numberOfRows = 0
        let contentSection = ThreadsContentSection(rawValue: section)

        if contentSection == .unacceptedThreads && dataSource.hasUnacceptedThreads {
            numberOfRows = 1
        } else {
            numberOfRows = dataSource.acceptedThreadsCount
        }

        return numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell = UITableViewCell(frame: .zero)

        let contentSection = ThreadsContentSection(rawValue: indexPath.section)

        let isMessagesRequestsRow = dataSource.hasUnacceptedThreads && contentSection == .unacceptedThreads
        if isMessagesRequestsRow {
            cell = messagesRequestsCell(for: indexPath)
        } else if let thread = dataSource.acceptedThread(at: indexPath.row, in: 0) {
            let threadCellConfigurator = ThreadCellConfigurator(thread: thread)
            let cellData = threadCellConfigurator.cellData
            cell = tableView.dequeueReusableCell(withIdentifier: AvatarTitleSubtitleDetailsBadgeCell.reuseIdentifier, for: indexPath)

            threadCellConfigurator.configureCell(cell, with: cellData)
        }

        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

// MARK: - Threads Data Source Output

extension RecentViewController: ThreadsDataSourceOutput {

    func threadsDataSourceDidLoad() {
        tableView.reloadData()
        showEmptyStateIfNeeded()
    }
}

// MARK: - Profiles List Completion Output

extension RecentViewController: ProfilesListCompletionOutput {

    func didFinish(_ controller: ProfilesViewController, selectedProfilesIds: [String]) {
        controller.dismiss(animated: true, completion: nil)

        guard let selectedProfileAddress = selectedProfilesIds.first else { return }

        let thread = ChatInteractor.getOrCreateThread(for: selectedProfileAddress)
        thread.isPendingAccept = false
        thread.save()

        DispatchQueue.main.async {
            Navigator.tabbarController?.displayMessage(forAddress: selectedProfileAddress)
            self.dismiss(animated: true)
        }
    }
}

// MARK: - UITableViewDelegate

extension RecentViewController: UITableViewDelegate {

    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let contentSection = ThreadsContentSection(rawValue: indexPath.section) else { return }

        switch contentSection {
        case .unacceptedThreads:
            if dataSource.hasUnacceptedThreads {
                let messagesRequestsViewController = MessagesRequestsViewController(style: .grouped)
                navigationController?.pushViewController(messagesRequestsViewController, animated: true)
            } else {
                showThread(at: indexPath)
            }
        case .acceptedThreads:
           showThread(at: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let contentSection = ThreadsContentSection(rawValue: indexPath.section) else { return false }

        if contentSection == .unacceptedThreads && dataSource.hasUnacceptedThreads {
            return false
        }

        return true
    }

    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let action = UITableViewRowAction(style: .destructive, title: "Delete") { _, indexPath in
            if let thread = self.dataSource.acceptedThread(at: indexPath.row, in: 0) {

                ChatInteractor.deleteThread(thread)
            }
        }

        return [action]
    }
}
