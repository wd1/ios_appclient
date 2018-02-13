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
import SweetUIKit

protocol OfflineAlertDisplaying: class {
    var offlineAlertView: OfflineAlertView { get }

    func setupOfflineAlertView(hidden: Bool)
    func showOfflineAlertView()
    func hideOfflineAlertView()
}

extension OfflineAlertDisplaying where Self: UITabBarController {

    func setupOfflineAlertView(hidden: Bool = false) {
        view.insertSubview(offlineAlertView, aboveSubview: tabBar)

        offlineAlertView.topToBottom(of: view)
        offlineAlertView.left(to: view)
        offlineAlertView.right(to: view)

        if !hidden {
            showOfflineAlertView()
        }
    }

    static func defaultOfflineAlertView() -> OfflineAlertView {
        return OfflineAlertView(withAutoLayout: true)
    }

    func showOfflineAlertView() {
        DispatchQueue.main.async {
            self.view.bringSubview(toFront: self.offlineAlertView)
            self.offlineAlertView.isHidden = false
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeInOutFromCurrentStateWithUserInteraction, animations: {
                self.offlineAlertView.transform = self.offlineAlertView.displayTransform
                self.tabBar.transform = self.offlineAlertView.displayTransform
            }, completion: nil)
        }

        DispatchQueue.main.asyncAfter(seconds: 2.2) {
            self.hideOfflineAlertView()
        }
    }

    func hideOfflineAlertView() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeInOutFromCurrentStateWithUserInteraction, animations: {
                self.offlineAlertView.transform = .identity
                self.tabBar.transform = .identity
            }, completion: { _ in
                self.offlineAlertView.isHidden = true
            })
        }
    }
}
