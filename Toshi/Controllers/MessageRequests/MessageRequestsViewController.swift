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

final class MessagesRequestsViewController: SweetTableController {

    private lazy var dataSource: ThreadsDataSource = {
        let dataSource = ThreadsDataSource(target: .unacceptedThreadRequests)
        dataSource.output = self

        return dataSource
    }()

    let idAPIClient = IDAPIClient.shared

    override init(style: UITableViewStyle) {
        super.init(style: style)

        title = dataSource.title
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        BasicTableViewCell.register(in: tableView)
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.showsVerticalScrollIndicator = true
        tableView.alwaysBounceVertical = true

        dataSource.output = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(true)
        tabBarController?.tabBar.isHidden = false

        dismissIfNeeded(animated: false)
    }

    func dismissIfNeeded(animated: Bool = true) {

        if Navigator.topNonModalViewController == self && dataSource.unacceptedThreadsCount == 0 {
            navigationController?.popViewController(animated: animated)
        }
    }

    private func openThread(_ thread: TSThread) {
        let chatViewController = ChatViewController(thread: thread)
        navigationController?.pushViewController(chatViewController, animated: true)
    }
}

extension MessagesRequestsViewController: UITableViewDataSource {

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.unacceptedThreadsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellConfigurator = CellConfigurator()

        guard let thread = dataSource.unacceptedThread(at: indexPath) else { return UITableViewCell(frame: .zero) }

        let avatar = thread.avatar()
        var subtitle = "..."
        var title = ""

        if thread.isGroupThread() {
            title = thread.name()
        } else if let recipient = thread.recipient() {
            title = recipient.nameOrDisplayName
        }

        if let message = thread.messages.last, let messageBody = message.body {
            switch SofaType(sofa: messageBody) {
            case .message:
                if message.hasAttachments() {
                    subtitle = Localized("attachment_message_preview_string")
                } else {
                    subtitle = SofaMessage(content: messageBody).body
                }
            case .paymentRequest:
                subtitle = Localized("payment_request_message_preview_string")
            case .payment:
                subtitle = Localized("payment_message_preview_string")
            default:
                break
            }
        }

        let cellData = TableCellData(title: title, subtitle: subtitle, leftImage: avatar, doubleActionImages: (firstImage: UIImage(named: "accept_thread_icon")!, secondImage: UIImage(named: "decline_thread_icon")!))
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellConfigurator.cellIdentifier(for: cellData.components), for: indexPath) as? BasicTableViewCell else { return UITableViewCell(frame: .zero) }
        cellConfigurator.configureCell(cell, with: cellData)
        cell.actionDelegate = self

        return cell
    }
}

extension MessagesRequestsViewController: BasicCellActionDelegate {

    func didTapFirstActionButton(_ cell: BasicTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let thread = dataSource.unacceptedThread(at: indexPath) else { return }

        ChatInteractor.acceptThread(thread)

        openThread(thread)
    }

    func didTapSecondActionButton(_ cell: BasicTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let thread = dataSource.unacceptedThread(at: indexPath) else { return }

        ChatInteractor.declineThread(thread)
    }
}

extension MessagesRequestsViewController: ThreadsDataSourceOutput {

    func threadsDataSourceDidLoad() {
        tableView.reloadData()
        dismissIfNeeded()
    }
}

extension MessagesRequestsViewController: UITableViewDelegate {

    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let thread = dataSource.unacceptedThread(at: indexPath) else { return }
        let chatViewController = ChatViewController(thread: thread)
        
        navigationController?.pushViewController(chatViewController, animated: true)
    }
}
