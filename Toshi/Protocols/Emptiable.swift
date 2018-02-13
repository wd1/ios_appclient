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

protocol Emptiable: class {
    var emptyView: EmptyView { get }
    func emptyViewButtonPressed(_ button: ActionButton)
}

class EmptyView: UIView {
    
    private(set) lazy var actionButton: ActionButton = {
        let view = ActionButton(margin: 30)
        view.setButtonStyle(.primary)
        
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Theme.preferredSemibold()
        label.adjustsFontForContentSizeCategory = true
        
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Theme.preferredRegular()
        label.adjustsFontForContentSizeCategory = true
        
        return label
    }()

    var title = "" {
        didSet {
            titleLabel.text = title
        }
    }

    var buttonTitle = "" {
        didSet {
            actionButton.title = buttonTitle
        }
    }
    
    private lazy var layoutGuide = UILayoutGuide()
    
    convenience init(title: String, description: String, buttonTitle: String) {
        self.init()
        
        addLayoutGuide(layoutGuide)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(actionButton)
        
        layoutGuide.left(to: self, offset: 30)
        layoutGuide.right(to: self, offset: -30)
        layoutGuide.centerY(to: self)
        
        titleLabel.top(to: layoutGuide)
        titleLabel.left(to: layoutGuide)
        titleLabel.right(to: layoutGuide)

        descriptionLabel.topToBottom(of: titleLabel, offset: 20)
        descriptionLabel.left(to: layoutGuide)
        descriptionLabel.right(to: layoutGuide)

        actionButton.topToBottom(of: descriptionLabel, offset: 30)
        actionButton.centerX(to: self)
        actionButton.bottom(to: layoutGuide)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 3
        descriptionLabel.attributedText = NSMutableAttributedString(string: description, attributes: [.paragraphStyle: paragraphStyle])

        titleLabel.text = title
        actionButton.title = buttonTitle
    }
}
