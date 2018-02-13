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

/// A little quick alert that shows at the bottom of a given view.
/// Useful for things where you wnat to provide visual feedback, but an
/// alert would be complete overkill.
final class QuickAlertView: UILabel {

    private weak var parentView: UIView?

    private let animationDuration: TimeInterval = 0.4

    // MARK: - Initialization

    /// Designated initializer.
    /// Note: The returned view will already be added to the passed-in parent.
    ///
    /// - Parameters:
    ///   - title: The text you wish to show in the view. Should be pretty short since this will get auto-hidden.
    ///   - parent: The view to show the quick alert in.
    ///   - bottomMargin: How far from the bottom of the parent the bottom of the alert view should appear. Defaults to 60
    ///   - shouldCompensateForTabBarOniOS10: True if there's a tab bar at the bottom of the view where this alert should be shown that should cause the offset to be updated, false if not. Defaults to true.
    init(title: String,
         in parent: UIView,
         bottomMargin: CGFloat = 20,
         shouldCompensateForTabBarOniOS10: Bool = true) {
        parentView = parent
        super.init(frame: .zero)

        font = Theme.preferredFootnote()
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        textColor = Theme.lightTextColor
        textAlignment = .center
        text = title
        numberOfLines = 0

        alpha = 0.0
        layer.cornerRadius = 8
        clipsToBounds = true

        parent.addSubview(self)

        if #available(iOS 11, *) {
            bottom(to: parent.safeAreaLayoutGuide, offset: -bottomMargin)
        } else {
            if shouldCompensateForTabBarOniOS10 {
                let tabBarHeight: CGFloat = 49
                bottom(to: parent, offset: -(bottomMargin + tabBarHeight))
            } else {
                bottom(to: parent, offset: -bottomMargin)
            }
        }

        centerX(to: parent)

        setHugging(.required, for: .horizontal)
        widthToSuperview(multiplier: 0.8,
                         relation: .equalOrLess,
                         priority: .defaultHigh)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Padding

    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize

        // Multiplied by two so applied to left + right / top + bottom
        contentSize.width += (.mediumInterItemSpacing * 2)
        contentSize.height += (.smallInterItemSpacing * 2)

        return contentSize
    }

    // MARK: - Animation

    /// Basic method to have the view show then hide automatically.
    ///
    /// - Parameters:
    ///   - length: The number of seconds the view should stay on screen before fading out again. Defaults to 1.
    ///   - completion: A completion block to fire when the hide is completed.
    func showThenHide(after length: TimeInterval = 1, completion: (() -> Void)? = nil) {
        guard let parent = parentView else { /* parent got dealloced */ return }

        parent.addSubview(self)
        show(completion: { [weak self] in
            self?.hide(after: length, completion: completion)
        })
    }

    private func show(completion: @escaping () -> Void) {
        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: [.curveEaseOut],
                       animations: {
                           self.alpha = 1.0
                       },
                       completion: { _ in
                           completion()
                       })
    }

    private func hide(after delay: TimeInterval, completion: (() -> Void)?) {
        UIView.animate(withDuration: animationDuration,
                       delay: delay,
                       options: [.curveEaseIn],
                       animations: {
                           self.alpha = 0
                       },
                       completion: { _ in
                           self.removeFromSuperview()
                           completion?()
                       })
    }
}
