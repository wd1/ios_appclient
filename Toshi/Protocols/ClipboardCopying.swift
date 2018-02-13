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

protocol ClipboardCopying {

    /// Copies the passed-in string to the clipboard.
    ///
    /// - Parameter string: The string to copy to the clipboard
    func copyStringToClipboard(_ string: String)

    /// Gets the current string contents of the clipboard.
    ///
    /// - Returns: The current string contents of the clipboard.
    func stringFromClipboard() -> String?
}

// MARK: - Generic default implementation

extension ClipboardCopying {

    func copyStringToClipboard(_ string: String) {
        UIPasteboard.general.string = string
    }

    func stringFromClipboard() -> String? {
        return UIPasteboard.general.string
    }

    /// Copies a string to the clipboard then shows a quick alert to provide visual feedback to the user
    ///
    /// - Parameters:
    ///   - string: The string to copy to the clipboard.
    ///   - message: The message to show in the quick alert. Defaults to a generic message inidcating something was copied to the clipboard.
    ///   - view: The view to show the quick alert in
    func copyStringToClipboard(_ string: String,
                               thenShowMessage message: String = Localized("clipboard_copied_alert_text"),
                               in view: UIView) {
        copyStringToClipboard(string)

        guard view.subviews.first(where: { $0 is QuickAlertView }) == nil else { /* Alert view already showing */ return }

        QuickAlertView(title: message, in: view).showThenHide()
    }

    /// Copies a string to the clipboard then updates the actionable state of a confirmation button
    ///
    /// - Parameters:
    ///   - string: The string to copy to the clipboard
    ///   - button: The confirmation button whose state you wish to update.
    func copyStringToClipboard(_ string: String,
                               thenUpdate button: ConfirmationButton) {
        copyStringToClipboard(string)

        DispatchQueue.main.asyncAfter(seconds: 0.1) {
            button.contentState = button.contentState == .actionable ? .confirmation : .actionable
        }
    }
}

// MARK: - Default implemetation for UIViewControllers

extension ClipboardCopying where Self: UIViewController {

    /// Copies a string to the clipboard then shows a quick alert to provide visual feedback to the user in the view controller's view
    ///
    /// - Parameters:
    ///   - string: The string to copy to the clipboard.
    func copyToClipboardWithGenericAlert(_ string: String) {
        self.copyStringToClipboard(string,
                                   in: view)
    }
}
