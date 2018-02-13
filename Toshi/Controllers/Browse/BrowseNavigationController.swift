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

class BrowseNavigationController: UINavigationController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override init(rootViewController: UIViewController) {
        
        if let profileData = UserDefaultsWrapper.selectedApp {
            super.init(nibName: nil, bundle: nil)
            guard let json = (try? JSONSerialization.jsonObject(with: profileData, options: [])) as? [String: Any] else { return }
            
            viewControllers = [rootViewController, ProfileViewController(profile: TokenUser(json: json))]
            configureTabBarItem()
        } else {
            super.init(rootViewController: rootViewController)
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configureTabBarItem()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureTabBarItem() {
        tabBarItem = UITabBarItem(title: Localized("tab_bar_title_browse"), image: #imageLiteral(resourceName: "tab1"), tag: 0)
        tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)

        if let viewController = viewController as? ProfileViewController {
            UserDefaultsWrapper.selectedApp = viewController.profile.json
        }
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        UserDefaultsWrapper.selectedApp = nil
        return super.popViewController(animated: animated)
    }

    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        UserDefaultsWrapper.selectedApp = nil
        return super.popToRootViewController(animated: animated)
    }

    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        UserDefaultsWrapper.selectedApp = nil
        return super.popToViewController(viewController, animated: animated)
    }
}
