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

import SweetUIKit
import TinyConstraints
import UIKit

protocol ProfilesAddGroupHeaderDelegate: class {
    func newGroup()
}

class ProfilesAddGroupHeader: UIView {
    
    private weak var delegate: ProfilesAddGroupHeaderDelegate?

    private lazy var button: LeftAlignedButton = {
        let view = LeftAlignedButton()
        view.icon = UIImage(color: .lightGray, size: CGSize(width: 48, height: 48))
        view.title = Localized("profiles_new_group")
        view.icon = UIImage(named: "navigation_bar_add")
        view.titleColor = Theme.tintColor
        view.addTarget(self,
                       action: #selector(tappedAddGroup),
                       for: .touchUpInside)
        return view
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor
        
        return view
    }()
    
    convenience init(with delegate: ProfilesAddGroupHeaderDelegate?) {
        self.init(withAutoLayout: true)
        self.delegate = delegate
        
        self.addSubview(button)
        button.edgesToSuperview()
        
        self.addSubview(separatorView)
        separatorView.height(.lineHeight)
        separatorView.edgesToSuperview(excluding: .top)
    }
    
    @objc private func tappedAddGroup() {
        guard let delegate = delegate else {
            assertionFailure("No delegate for you!")
            return
        }
        
        delegate.newGroup()
    }
}
