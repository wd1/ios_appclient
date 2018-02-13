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
import UserNotifications

class SignalNotificationManager: NSObject, NotificationsProtocol {

    public func notifyUser(for incomingMessage: TSIncomingMessage, in thread: TSThread, contactsManager: ContactsManagerProtocol, transaction: YapDatabaseReadTransaction) {
        
        DispatchQueue.main.async {
            guard UIApplication.shared.applicationState == .background || Navigator.tabbarController?.selectedViewController != Navigator.tabbarController?.messagingController else {
                return
            }
            
            defer { SignalNotificationManager.updateUnreadMessagesNumber() }
            
            let content = UNMutableNotificationContent()
            content.title = thread.name()
            content.threadIdentifier = thread.uniqueId
            
            if let body = incomingMessage.body, let sofa = SofaWrapper.wrapper(content: body) as? SofaMessage {
                content.body = sofa.body
            } else {
                content.body = Localized("APN_Message")
            }
            
            content.sound = UNNotificationSound(named: "PN.m4a")
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            let center = UNUserNotificationCenter.current()
            center.add(request, withCompletionHandler: nil)
        }
    }

    func notifyUser(for error: TSErrorMessage!, in thread: TSThread!) {
        DLog("Error: \(error), in thread: \(thread).")
    }

    @objc static func updateUnreadMessagesNumber() {
        DispatchQueue.main.async {
            let unreadMessagesCount = Int(OWSMessageManager.shared().unreadMessagesCount())
            
            if unreadMessagesCount > 0 {
                Navigator.tabbarController?.messagingController.tabBarItem.badgeValue = "\(unreadMessagesCount)"
                Navigator.tabbarController?.messagingController.tabBarItem.badgeColor = .red
            } else {
                Navigator.tabbarController?.messagingController.tabBarItem.badgeValue = nil
            }
        }
    }

    static func unreadMessagesCount(in thread: TSThread) -> Int {
        return Int(OWSMessageManager.shared().unreadMessages(in: thread))
    }
}
