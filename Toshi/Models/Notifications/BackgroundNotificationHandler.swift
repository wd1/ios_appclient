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
import UserNotifications

class BackgroundNotificationHandler: NSObject {

    @objc static func handle(_ notification: UNNotification, _ completion: @escaping ((_ options: UNNotificationPresentationOptions) -> Void)) {

        let body = notification.request.content.body

        if SofaType(sofa: body) == .none {
            completion([.badge, .sound, .alert])

            return
        }

        if SofaWrapper.wrapper(content: body) as? SofaMessage != nil {
            completion([.badge, .sound, .alert])

            return
        }

        if let payment = SofaWrapper.wrapper(content: body) as? SofaPayment, payment.status == .confirmed {
            enqueueLocalNotification(for: payment)
            completion([])

            return
        }

        completion([.badge, .sound, .alert])
    }

    static func enqueueLocalNotification(for payment: SofaPayment) {
        let content = UNMutableNotificationContent()
        content.title = Localized("notification_payment_received_in_background_title")

        let value = EthereumConverter.fiatValueString(forWei: payment.value, exchangeRate: ExchangeRateClient.exchangeRate)
        let format = Localized("notification_payment_received_in_background_message_format")
        content.body = String(format: format, value)

        content.sound = UNNotificationSound(named: "PN.m4a")

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: content.title, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: nil)
    }
}
