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

/// Extension functions checking if the app is currently running tests or not.
public extension UIApplication {

    /// Returns true if any kind of testing is taking place, false if not.
    public static var isTesting: Bool {
        return NSClassFromString("XCTestCase") != nil || NSClassFromString("QuickSpec") != nil
    }

    /// Returns true if testing which does not involve the UI is taking place, false if not.
    public static var isNonUITesting: Bool {
        return isTesting && !isUITesting
    }

    /// Returns true if UI testing is taking place, false if not.
    public static var isUITesting: Bool {
        return NSClassFromString("GREYActions") != nil
    }
}
