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

import TinyConstraints
import UIKit

extension UIStackView {
    
    /// Adds given view as an arranged subview and constrains it to either the left and right or top and bottom of the caller, based on the caller's axis.
    /// A vertical stack view will cause a subview to be constrained to the left and right, since top and bottom are handled by the stack view.
    /// A horizontal stack view will cause a subview to be constrained to the top and bottom, since left and right are handled by the stack view.
    ///
    /// - Parameters:
    ///   - view: The view to add and constrain.
    ///   - margin: Any additional margin to add. Defaults to zero. Will be the same on both sides it is applied to.
    func addWithDefaultConstraints(view: UIView, margin: CGFloat = 0) {
        self.addArrangedSubview(view)
        
        switch self.axis {
        case .vertical:
            view.left(to: self, offset: margin)
            view.right(to: self, offset: -margin)
        case .horizontal:
            view.top(to: self, offset: margin)
            view.bottom(to: self, offset: -margin)
        }
    }

    /// Adds a border view as an arranged subview and sets up its height constraint.
    ///
    /// - Parameter margin: The margin to use when adding the border. Defaults to zero
    /// - Returns: The added border view.
    @discardableResult
    func addStandardBorder(margin: CGFloat = 0) -> BorderView {
        let border = BorderView()
        addWithDefaultConstraints(view: border, margin: margin)
        border.addHeightConstraint()

        return border
    }
    
    /// Adds the given view as an arranged subview, and constrains it to the center of the opposite axis of the stack view.
    /// A vertical stack view will cause a subview to be constrained to the center X of the stackview.
    /// A horizontal stack view will cause a subview to be constrained to the center Y of the stackview.
    ///
    /// - Parameter view: The view to add and constrain.
    func addWithCenterConstraint(view: UIView) {
        self.addArrangedSubview(view)
        
        switch self.axis {
        case .vertical:
            view.centerX(to: self)
        case .horizontal:
            view.centerY(to: self)
        }
    }
    
    /// Adds a background view to force a background color to be drawn.
    /// https://stackoverflow.com/a/42256646/681493
    ///
    /// - Parameters:
    ///   - color: The color for the background.
    ///   - margin: [Optional] The margin to add around the view. Useful when there's a margin where the view is pinned which you want to make sure has the appropriate background color. When nil, edges will simply be pinned to the stack view itself.
    func addBackground(with color: UIColor, margin: CGFloat? = nil) {
        let background = UIView()
        background.backgroundColor = color
        
        self.addSubview(background)
        if let margin = margin {
            background.topToSuperview(offset: -margin)
            background.leftToSuperview(offset: -margin)
            background.rightToSuperview(offset: -margin)
            background.bottomToSuperview(offset: margin)
        } else {
            background.edgesToSuperview()
        }
    }
    
    private static let spacerTag = 12345
    
    /// Backwards compatibile way to add custom spacing between views of a stack view
    /// NOTE: When iOS 11 support is dropped, this should be removed and `setCustomSpacing` should be used directly.
    /// ALSO NOTE: On iOS 11, this doesn't work if there's no view below the view where you've added the custom spacing. Use `addSpacerView(with:after:)` instead.
    ///
    /// - Parameters:
    ///   - spacing: The amount of spacing to add.
    ///   - view: The view to add the spacing after (to the right for horizontal, below for vertical)
    func addSpacing(_ spacing: CGFloat, after view: UIView) {
        if #available(iOS 11, *) {
            setCustomSpacing(spacing, after: view)
        } else {
            guard let indexOfViewToInsertAfter = self.arrangedSubviews.index(of: view) else {
                assertionFailure("You need to insert after one of the arranged subviews of this stack view!")
                return
            }
            
            addSpacerView(with: spacing, after: indexOfViewToInsertAfter)
        }
    }

    /// Inserts or adds a spacer view of the given size. Note that this should be used for bottom spacing - adding custom spacing in iOS 11 only works if there is a view below where you've added the custom spacing.
    ///
    /// - Parameters:
    ///   - spacing: The amount of spacing to add.
    ///   - indexOfViewToInsertAfter: [optional] The index to insert the view after, or nil to just add to the end. Defaults to nil
    func addSpacerView(with spacing: CGFloat, after indexOfViewToInsertAfter: Int? = nil) {
        let spacerView = UIView()
        spacerView.tag = UIStackView.spacerTag
        spacerView.backgroundColor = .clear
        spacerView.setContentCompressionResistancePriority(.required, for: axis)

        if let index = indexOfViewToInsertAfter {
            insertArrangedSubview(spacerView, at: (index + 1))
        } else {
            addArrangedSubview(spacerView)
        }

        switch axis {
        case .vertical:
            spacerView.height(spacing)
            spacerView.left(to: self)
            spacerView.right(to: self)
        case .horizontal:
            spacerView.width(spacing)
            spacerView.top(to: self)
            spacerView.bottom(to: self)
        }
    }
}
