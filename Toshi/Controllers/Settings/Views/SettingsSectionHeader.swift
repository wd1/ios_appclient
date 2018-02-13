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
import SweetUIKit

class SettingsSectionHeader: UIView {

    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = Theme.sectionTitleColor
        view.font = Theme.preferredFootnote()
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    lazy var errorLabel: UILabel = {
        let view = UILabel()
        view.textColor = Theme.errorColor
        view.font = Theme.preferredFootnote()
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    lazy var errorImage = UIImageView(image: #imageLiteral(resourceName: "error"))
    
    convenience init(title: String, error: String? = nil) {
        self.init()
        
        addSubview(titleLabel)
        titleLabel.bottom(to: self, offset: -6)
        titleLabel.text = title.uppercased()
        errorLabel.text = error
        
        if self.errorLabel.text != nil {
            addSubview(errorLabel)
            addSubview(errorImage)
            
            titleLabel.left(to: self, offset: 15)
            
            errorLabel.centerY(to: titleLabel)
            errorLabel.left(to: titleLabel, relation: .equalOrGreater)
            errorLabel.rightToLeft(of: errorImage, offset: -5)
            
            errorImage.centerY(to: errorLabel)
            errorImage.size(CGSize(width: 16, height: 16))
            errorImage.right(to: self, offset: -15)
        } else {
            titleLabel.left(to: self, offset: 15)
            titleLabel.right(to: self, offset: -15)
        }
    }

    func setErrorHidden(_ hidden: Bool) {
        errorLabel.alpha = hidden ? 0.0 : 1.0
        errorImage.alpha = hidden ? 0.0 : 1.0
    }
}
