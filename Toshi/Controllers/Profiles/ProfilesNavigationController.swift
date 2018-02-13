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

final class ProfilesNavigationController: UINavigationController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    // MARK: - Initialization
    
    override init(rootViewController: UIViewController) {
        if let rootViewController = rootViewController as? ProfilesViewController, let address = UserDefaultsWrapper.selectedContact, rootViewController.type != .newChat {
            super.init(nibName: nil, bundle: nil)
            
            rootViewController.dataSource.uiDatabaseConnection.read { [weak self] transaction in
                if let data = transaction.object(forKey: address, inCollection: TokenUser.favoritesCollectionKey) as? Data, let user = TokenUser.user(with: data) {
                    self?.viewControllers = [rootViewController, ProfileViewController(profile: user)]
                    self?.configureTabBarItem()
                }
            }
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
    
    // MARK: - Configuration
    
    private func configureTabBarItem() {
        tabBarItem = UITabBarItem(title: Localized("tab_bar_title_favorites"), image: #imageLiteral(resourceName: "tab4"), tag: 1)
        tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }
    
    // MARK: - Overrides around chaging VC
    
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
