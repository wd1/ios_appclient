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

extension UIView {

    static func highlightAnimation(_ animations: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOutFromCurrentStateWithUserInteraction, animations: animations, completion: nil)
    }

    func bounce() {
        transform = CGAffineTransform(scaleX: 0.98, y: 0.98)

        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 200, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
            self.transform = .identity
        }, completion: nil)
    }

    func shake() {
        transform = CGAffineTransform(translationX: 10, y: 0)

        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 50, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
            self.transform = .identity
        }, completion: nil)
    }

    /// Turns the current view into a circle by updating the corner radius to be half the width.
    /// Note: Might look a little silly if the view isn't a square.
    func circleify() {
        self.layer.cornerRadius = self.frame.width / 2
    }

    /// Adds a 1pt border only if debugging.
    ///
    /// - Parameter color: The color of the border you want to add.
    func showDebugBorder(color: UIColor) {
        #if DEBUG
            addBorder(ofColor: color)
        #endif
    }

    /// Adds a border.
    ///
    /// - Parameters:
    ///   - color: The UIColor of the border.
    ///   - width: The width of the border. Defaults to 1pt.
    func addBorder(ofColor color: UIColor, width: CGFloat = 1) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }

    /// Creates a shadow on the current view.
    /// NOTE: Shadows don't show up if you're clipping to bounds, so an assertion failure will occur if `clipsToBounds` is true.
    ///
    /// - Parameters:
    ///   - xOffset: The amount to offset the shadow horizontally
    ///   - yOffset: The amount to offset the shadow vertically
    ///   - radius: The blur radius of the shadow
    ///   - opacity: The opacity of the shadow color. Defaults to 0.5.
    ///   - color: The shadow color. Defaults to black.
    func addShadow(xOffset: CGFloat,
                   yOffset: CGFloat,
                   radius: CGFloat,
                   opacity: Float = 0.5,
                   color: UIColor = UIColor.black) {
        guard clipsToBounds == false else {
            assertionFailure("A shadow won't show up if you're clipping to bounds")
            return
        }

        layer.shadowOpacity = opacity
        layer.shadowOffset = CGSize(width: xOffset, height: yOffset)
        layer.shadowRadius = radius
        layer.shadowColor = color.cgColor
    }
}
