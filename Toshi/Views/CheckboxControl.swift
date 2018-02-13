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

class CheckboxControl: UIControl {

    lazy var checkbox: Checkbox = {
        let view = Checkbox()
        view.checked = false
        view.isUserInteractionEnabled = false

        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.isUserInteractionEnabled = false
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    private lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .light)
    }()

    var title: String? {
        didSet {
            guard let title = self.title else { return }

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2.5
            paragraphStyle.paragraphSpacing = -4
            
            let attributes: [NSAttributedStringKey: Any] = [
                .font: Theme.preferredRegularMedium(),
                .foregroundColor: Theme.darkTextColor,
                .paragraphStyle: paragraphStyle
            ]
            
            self.titleLabel.attributedText = NSMutableAttributedString(string: title, attributes: attributes)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(checkbox)
        addSubview(titleLabel)

        checkbox.top(to: titleLabel.forFirstBaselineLayout)
        checkbox.left(to: self)
        checkbox.size(CGSize(width: 20, height: 20))

        titleLabel.edges(to: self, insets: UIEdgeInsets(top: 0, left: 35, bottom: 0, right: 0))
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted != oldValue {
                feedbackGenerator.impactOccurred()

                UIView.highlightAnimation {
                    self.checkbox.alpha = self.isHighlighted ? 0.6 : 1
                    self.titleLabel.alpha = self.isHighlighted ? 0.6 : 1
                }
            }
        }
    }
}
