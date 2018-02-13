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

class WalletNavigationController: UINavigationController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return (topViewController == viewControllers.first) ? .lightContent : .default
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        tabBarItem = UITabBarItem(title: Localized("tab_bar_title_wallet"), image: #imageLiteral(resourceName: "tab3"), tag: 0)
        tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset

        delegate = self
    }

    required init?(coder _: NSCoder) {
        fatalError("")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            self.navigationBar.prefersLargeTitles = true
        }
    }
}

extension WalletNavigationController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {

        let isGoingToShowRootViewController = viewController is WalletViewController

        let barTintColor = isGoingToShowRootViewController ? Theme.tintColor : nil
        let shadowImage = isGoingToShowRootViewController ? UIImage() : nil
        let titleTextAttributes = isGoingToShowRootViewController ? [ NSAttributedStringKey.foregroundColor: Theme.lightTextColor ] : nil

        let duration = animated ? 0.5 : 0.0
        UIView.animate(withDuration: duration) {
            self.navigationBar.barTintColor = barTintColor
            self.navigationBar.shadowImage = shadowImage
            self.navigationBar.titleTextAttributes = titleTextAttributes

            self.navigationBar.layoutIfNeeded()
        }
    }
}
