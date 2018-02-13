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

class RecentNavigationController: UINavigationController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        tabBarItem = UITabBarItem(title: Localized("tab_bar_title_recent"), image: #imageLiteral(resourceName: "tab2"), tag: 0)
        tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }

    lazy var backgroundBlur: BlurView = {
        let view = BlurView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false

        return view
    }()

    required init?(coder _: NSCoder) {
        fatalError("")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard #available(iOS 11.0, *) else {
            navigationBar.barStyle = .default
            navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
            
            navigationBar.insertSubview(backgroundBlur, at: 0)
            backgroundBlur.edges(to: navigationBar, insets: UIEdgeInsets(top: -20, left: 0, bottom: 0, right: 0))
            return
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard #available(iOS 11.0, *) else {
            navigationBar.sendSubview(toBack: backgroundBlur)
            return
        }
    }

    func openThread(withAddress address: String, completion: ((Any?) -> Void)? = nil) {
        _ = popToRootViewController(animated: false)
        guard let recentViewController = self.viewControllers.first as? RecentViewController else { return }

        if let thread = recentViewController.thread(withAddress: address) {
            let chatViewController = ChatViewController(thread: thread)
            pushViewController(chatViewController, animated: false)

            completion?(chatViewController)
        } else {
            completion?(nil)
        }
    }

    func openThread(withThreadIdentifier identifier: String, animated: Bool) {
        _ = self.popToRootViewController(animated: animated)
        guard let recentViewController = self.viewControllers.first as? RecentViewController else { return }
        guard let thread = recentViewController.thread(withIdentifier: identifier) else { return }

        let chatViewController = ChatViewController(thread: thread)
        self.pushViewController(chatViewController, animated: animated)
    }

    func openThread(_ thread: TSThread, animated: Bool) {
        let chatViewController = ChatViewController(thread: thread)
        self.pushViewController(chatViewController, animated: animated)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)

        if let viewController = viewController as? ChatViewController {
            UserDefaultsWrapper.selectedThreadAddress = viewController.thread.contactIdentifier()
        }
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        UserDefaultsWrapper.selectedThreadAddress = nil

        return super.popViewController(animated: animated)
    }

    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        UserDefaultsWrapper.selectedThreadAddress = nil

        return super.popToRootViewController(animated: animated)
    }

    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        UserDefaultsWrapper.selectedThreadAddress = nil

        return super.popToViewController(viewController, animated: animated)
    }
}
