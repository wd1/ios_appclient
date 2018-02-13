// Copyright (c) 2017 Token Browser, Inc
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

class FavoritesNavigationController: UINavigationController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        tabBarItem = UITabBarItem(title: Localized("tab_bar_title_favorites"), image: #imageLiteral(resourceName: "tab4"), tag: 1)
        tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }

    required init?(coder _: NSCoder) {
        fatalError("")
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        UserDefaultsWrapper.selectedContact = nil
        return super.popViewController(animated: animated)
    }

    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        UserDefaultsWrapper.selectedContact = nil
        return super.popToRootViewController(animated: animated)
    }

    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        UserDefaultsWrapper.selectedContact = nil
        return super.popToViewController(viewController, animated: animated)
    }
}
