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

class Navigator: NSObject {

    static var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }

    static var window: UIWindow? {
        return appDelegate?.window
    }

    static var rootViewController: UIViewController? {
        return window?.rootViewController
    }

    @objc static var tabbarController: TabBarController? {
        return window?.rootViewController as? TabBarController
    }

    @objc static var topViewController: UIViewController? {
        var topViewController = topNonModalViewController

        while topViewController?.presentedViewController != nil {
            topViewController = topViewController?.presentedViewController
        }

        return topViewController
    }

     static var topNonModalViewController: UIViewController? {
        return tabbarController?.currentNavigationController?.topViewController
    }

    static func push(_ viewController: UIViewController, from fromController: UIViewController? = nil, animated: Bool = true) {
        guard viewController.presentingViewController == nil else { return }

        if fromController?.navigationController != nil {
            fromController?.navigationController?.pushViewController(viewController, animated: animated)
        } else {
            tabbarController?.currentNavigationController?.pushViewController(viewController, animated: animated)
        }
    }

    static func present(_ viewController: UIViewController, from parentViewController: UIViewController?, animated: Bool, completion: (() -> Void)? = nil) {
        guard viewController.presentingViewController == nil else { return }

        if parentViewController?.presentedViewController != nil {
            parentViewController?.presentedViewController?.dismiss(animated: animated, completion: completion)
        }

        parentViewController?.present(viewController, animated: true, completion: nil)
    }

    static func presentScanner() {
        guard let scannerController = tabbarController?.scannerController else {
            assertionFailure("Can't retrieve scanner controller from tab bar controller")
            return
        }

        SoundPlayer.playSound(type: .menuButton)

        Navigator.presentModally(scannerController)
    }

    @objc static func presentModally(_ controller: UIViewController) {
        present(controller, from: topViewController, animated: true)
    }

    @objc public static func presentDismissableAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let action = UIAlertAction(title: Localized("alert-ok-action-title"), style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }

        alertController.addAction(action)

        presentModally(alertController)
    }

    // Navigation assumes the following structure:
    // TabBar controller contains a messages controller. Messages controller lists chats, and pushes threads.
    @objc static func navigate(to threadIdentifier: String, animated: Bool) {
        // make sure we don't do UI stuff in a background thread
        DispatchQueue.main.async {
            // get tab controller
            guard let tabController = UIApplication.shared.delegate?.window??.rootViewController as? TabBarController else { return }

            if tabController.presentedViewController != nil {
                tabController.dismiss(animated: animated)
            }

            _ = tabController.messagingController.popToRootViewController(animated: animated)
            tabController.messagingController.openThread(withThreadIdentifier: threadIdentifier, animated: animated)
            tabController.switch(to: .messaging)
        }
    }

    @objc static func openThread(_ thread: TSThread, animated: Bool) {
        guard let tabController = UIApplication.shared.delegate?.window??.rootViewController as? TabBarController else { return }

        if tabController.presentedViewController != nil {
            tabController.dismiss(animated: animated)
        }

        _ = tabController.messagingController.popToRootViewController(animated: animated)
        tabController.messagingController.openThread(thread, animated: true)
        tabController.switch(to: .messaging)
    }
}
