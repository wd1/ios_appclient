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

extension UIScrollView {
    func edgeInsets(from notification: NSNotification) -> UIEdgeInsets {
        guard let value = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return UIEdgeInsets.zero }

        var keyboardFrameEnd = CGRect.zero
        value.getValue(&keyboardFrameEnd)
        guard let keyboardFrameEndValue = (window?.convert(keyboardFrameEnd, to: superview)) else {
            return UIEdgeInsets.zero
        }

        var newScrollViewInsets = contentInset
        newScrollViewInsets.bottom = superview!.bounds.size.height - keyboardFrameEndValue.origin.y

        if #available(iOS 11.0, *) {
            newScrollViewInsets.bottom -= adjustedContentInset.bottom
        }

        return newScrollViewInsets
    }

    func addBottomInsets(_ insets: UIEdgeInsets) {
        contentInset = insets
        scrollIndicatorInsets = insets
    }

    func removeKeyboardInsets(from _: NSNotification, withBasicBottomInset basicBottomInset: CGFloat) {
        let insets = UIEdgeInsets(top: contentInset.top, left: contentInset.left, bottom: basicBottomInset, right: contentInset.right)
        contentInset = insets
        scrollIndicatorInsets = insets
    }

    func addBottomInsets(from notification: NSNotification) {
        let insets = edgeInsets(from: notification)
        contentInset = insets
        scrollIndicatorInsets = insets
    }
}
