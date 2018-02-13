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

class ProfilesAddedToGroupHeader: UIView {
    
    private lazy var profilesAddedLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor
        
        return view
    }()
    
    private var margin: CGFloat = 0
    
    convenience init(margin: CGFloat) {
        self.init(withAutoLayout: true)
        self.margin = margin
        addSubview(profilesAddedLabel)
        addSubview(separatorView)
        
        separatorView.height(.lineHeight)
        separatorView.edgesToSuperview(excluding: .top)
        
        profilesAddedLabel.edgesToSuperview(insets: UIEdgeInsets(top: margin,
                                                                 left: margin,
                                                                 bottom: margin,
                                                                 right: -margin))
        updateDisplay(with: [])
    }
    
    func updateDisplay(with profiles: Set<TokenUser>) {
        let nonNameAttributes = [ NSAttributedStringKey.foregroundColor: Theme.mediumTextColor.withAlphaComponent(0.4),
                                    NSAttributedStringKey.font: Theme.preferredRegular()]

        let toAttributes = [ NSAttributedStringKey.foregroundColor: Theme.mediumTextColor,
                                 NSAttributedStringKey.font: Theme.preferredRegular()]
        let toAttributedString = NSMutableAttributedString(string: Localized("profiles_add_to_group_prefix"), attributes: toAttributes)

        guard profiles.count > 0 else {
            let placeholderString = NSAttributedString(string: Localized("profiles_empty_group_placeholder"), attributes: nonNameAttributes)
            toAttributedString.append(placeholderString)
            profilesAddedLabel.attributedText = toAttributedString
            
            return
        }

        let sortedProfiles = profiles.sorted(by: { $0.name < $1.name })

        let nameStrings = sortedProfiles.map { NSAttributedString(string: $0.nameOrDisplayName, attributes: [ .foregroundColor: Theme.tintColor ]) }
        
        // `join(with:)` doesn't work on attributed strings, so:
        let singleNamesString = nameStrings.reduce(NSMutableAttributedString(), { accumulated, next in
            accumulated.append(next)
            
            // Don't add a comma after the last item
            guard next != nameStrings.last else { return accumulated }
            accumulated.append(NSAttributedString(string: ", ", attributes: nonNameAttributes))
            
            return accumulated
        })
    
        toAttributedString.append(singleNamesString)
        profilesAddedLabel.attributedText = toAttributedString
    }
}
