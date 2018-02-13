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

final class ThreadCellConfigurator: CellConfigurator {

    private var thread: TSThread

    lazy var messageAttributes: [NSAttributedStringKey: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2.5
        paragraphStyle.paragraphSpacing = -4
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [
            .kern: -0.4,
            .font: Theme.preferredRegularSmall(),
            .foregroundColor: Theme.greyTextColor,
            .paragraphStyle: paragraphStyle
        ]
    }()

    init(thread: TSThread) {
        self.thread = thread
    }

    lazy var cellData: TableCellData = {
        var avatar: UIImage?
        var subtitle = "..."
        var title = ""
        var details: String?
        var badgeText: String?
        if thread.isGroupThread() {
            avatar = (thread as? TSGroupThread)?.groupModel.avatarOrPlaceholder
            title = thread.name()
        } else if let recipient = thread.recipient() {
            avatar = AvatarManager.shared.cachedAvatar(for: recipient.avatarPath) ?? #imageLiteral(resourceName: "avatar-placeholder")
            title = recipient.nameOrDisplayName
        }

        if thread.hasUnreadMessages() {
            let unreadMessagesInThread = SignalNotificationManager.unreadMessagesCount(in: thread)
            badgeText = "\(unreadMessagesInThread)"
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

        let date = self.thread.lastMessageDate()

        if DateTimeFormatter.isDate(date, sameDayAs: Date()) {
            details = DateTimeFormatter.timeFormatter.string(from: date)
        } else {
            details = DateTimeFormatter.dateFormatter.string(from: date)
        }

        return TableCellData(title: title, subtitle: subtitle, leftImage: avatar, details: details, badgeText: badgeText)
    }()
}
