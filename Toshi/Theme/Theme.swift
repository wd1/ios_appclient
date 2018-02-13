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

extension CGFloat {
    
    /// The height of a single pixel on the screen.
    static var lineHeight: CGFloat {
        return 1 / UIScreen.main.scale
    }

    static let defaultButtonHeight: CGFloat = 44
    static let defaultBarHeight: CGFloat = 44
    static let defaultMargin: CGFloat = 15

    /// NOTE: Implicitly also the default avatar width.
    static let defaultAvatarHeight: CGFloat = 60

    // Spacing should be related to a base amount - multiply that base amount by a certain number to get final results
    
    static let spacingx1: CGFloat = 5
    static let spacingx2: CGFloat = (spacingx1 * 2)
    static let spacingx3: CGFloat = (spacingx1 * 3)
    static let spacingx4: CGFloat = (spacingx1 * 4)
    static let spacingx8: CGFloat = (spacingx1 * 8)

    // More readable aliases to various inter-item spacing.

    static let smallInterItemSpacing: CGFloat = spacingx1
    static let mediumInterItemSpacing: CGFloat = spacingx2
    static let largeInterItemSpacing: CGFloat = spacingx4
    static let giantInterItemSpacing: CGFloat = spacingx8
}

final class Theme: NSObject {}

extension Theme {
    
    @objc static func setupBasicAppearance() {
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.titleTextAttributes = [.font: Theme.semibold(size: 17), .foregroundColor: Theme.navigationTitleTextColor]
        navBarAppearance.tintColor = Theme.tintColor
        navBarAppearance.barTintColor = Theme.navigationBarColor
        
        let barButtonAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
        barButtonAppearance.setTitleTextAttributes([.font: Theme.regular(size: 17), .foregroundColor: Theme.tintColor], for: .normal)
        
        let alertAppearance = UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self])
        alertAppearance.tintColor = Theme.tintColor
    }
}

extension Theme {
    
    static var lightTextColor: UIColor {
        return .white
    }

    static var mediumTextColor: UIColor {
        return UIColor(hex: "99999D")
    }

    static var darkTextColor: UIColor {
        return .black
    }

    static var greyTextColor: UIColor {
        return UIColor(hex: "A4A4AB")
    }

    static var lightGreyTextColor: UIColor {
        return UIColor(hex: "7D7C7C")
    }

    static var lighterGreyTextColor: UIColor {
        return UIColor(hex: "F3F3F3")
    }

    @objc static var tintColor: UIColor {
        #if TOSHIDEV
            return UIColor(hex: "007AFF")
        #else
            return UIColor(hex: "01C236")
        #endif
    }

    static var sectionTitleColor: UIColor {
        return UIColor(hex: "78787D")
    }

    @objc static var viewBackgroundColor: UIColor {
        return .white
    }

    static var unselectedItemTintColor: UIColor {
        return UIColor(hex: "979ca4")
    }
    
    static var lightGrayBackgroundColor: UIColor {
        return UIColor(hex: "EFEFF4")
    }

    static var inputFieldBackgroundColor: UIColor {
        return UIColor(hex: "F1F1F1")
    }
    
    static var chatInputFieldBackgroundColor: UIColor {
        return UIColor(hex: "FAFAFA")
    }

    @objc static var navigationTitleTextColor: UIColor {
        return .black
    }

    @objc static var navigationBarColor: UIColor {
        return UIColor(hex: "F7F7F8")
    }

    static var borderColor: UIColor {
        return UIColor(hex: "D7DBDC")
    }

    static var actionButtonTitleColor: UIColor {
        return UIColor(hex: "0BBEE3")
    }

    static var ratingBackground: UIColor {
        return UIColor(hex: "D1D1D1")
    }

    static var ratingTint: UIColor {
        return UIColor(hex: "EB6E00")
    }

    static var passphraseVerificationContainerColor: UIColor {
        return UIColor(hex: "EAEBEC")
    }

    static var cellSelectionColor: UIColor {
        return UIColor(white: 0.95, alpha: 1)
    }

    static var separatorColor: UIColor {
        return UIColor(white: 0.95, alpha: 1)
    }
    
    static var incomingMessageBackgroundColor: UIColor {
        return UIColor(hex: "ECECEE")
    }

    static var outgoingMessageTextColor: UIColor {
        return .white
    }

    static var incomingMessageTextColor: UIColor {
        return .black
    }

    static var errorColor: UIColor {
        return UIColor(hex: "FF0000")
    }

    static var offlineAlertBackgroundColor: UIColor {
        return UIColor(hex: "5B5B5B")
    }

    static var inactiveButtonColor: UIColor {
        return UIColor(hex: "B6BCBF")
    }
}

// MARK: - Fonts

extension Theme {
    
    private static func dynamicType(for preferredFont: UIFont, withStyle style: UIFontTextStyle, inSizeRange range: ClosedRange<CGFloat>) -> UIFont {
        let font: UIFont

        if #available(iOS 11.0, *) {
            let metrics = UIFontMetrics(forTextStyle: style)
            font = metrics.scaledFont(for: preferredFont, maximumPointSize: range.upperBound)
        } else {
            font = .preferredFont(forTextStyle: style)
        }
        
        let augmentedFontSize = font.pointSize.clamp(to: range)
        
        return font.withSize(augmentedFontSize)
    }
    
    @objc static func emoji() -> UIFont {
        return .systemFont(ofSize: 50)
    }
    
    static func preferredFootnote(range: ClosedRange<CGFloat> = 13...30) -> UIFont {
        return dynamicType(for: regular(size: 13), withStyle: .footnote, inSizeRange: range)
    }
     
    static func preferredFootnoteBold(range: ClosedRange<CGFloat> = 13...30) -> UIFont {
        return dynamicType(for: bold(size: 13), withStyle: .footnote, inSizeRange: range)
    }

    static func preferredTitle1(range: ClosedRange<CGFloat> = 34...40) -> UIFont {
        return dynamicType(for: bold(size: 34), withStyle: .title1, inSizeRange: range)
    }
    
    static func preferredTitle2(range: ClosedRange<CGFloat> = 22...35) -> UIFont {
        return dynamicType(for: bold(size: 22), withStyle: .title2, inSizeRange: range)
    }

    static func preferredTitle3(range: ClosedRange<CGFloat> = 20...30) -> UIFont {
        return dynamicType(for: regular(size: 16), withStyle: .title3, inSizeRange: range)
    }
    
    static func preferredDisplayName(range: ClosedRange<CGFloat> = 25...35) -> UIFont {
        return dynamicType(for: bold(size: 25), withStyle: .title2, inSizeRange: range)
    }
    
    static func preferredRegular(range: ClosedRange<CGFloat> = 17...30) -> UIFont {
        return dynamicType(for: regular(size: 17), withStyle: .body, inSizeRange: range)
    }
    
    static func preferredRegularText(range: ClosedRange<CGFloat> = 17...30) -> UIFont {
        return dynamicType(for: regularText(size: 17), withStyle: .body, inSizeRange: range)
    }

    static func preferredRegularMonospaced(range: ClosedRange<CGFloat> = 15...30) -> UIFont {
        return dynamicType(for: regularMonospaced(size: 15), withStyle: .body, inSizeRange: range)
    }

    static func preferredRegularMedium(range: ClosedRange<CGFloat> = 17...30) -> UIFont {
        return dynamicType(for: medium(size: 17), withStyle: .callout, inSizeRange: range)
    }
    
    static func preferredRegularSmall(range: ClosedRange<CGFloat> = 16...30) -> UIFont {
        return dynamicType(for: regular(size: 16), withStyle: .subheadline, inSizeRange: range)
    }
    
    static func preferredSemibold(range: ClosedRange<CGFloat> = 17...30) -> UIFont {
        return dynamicType(for: semibold(size: 17), withStyle: .headline, inSizeRange: range)
    }
    
    // MARK: Default fonts

    private static func font(named name: String, size: CGFloat) -> UIFont {
        guard let font = UIFont(name: name, size: size) else {
            fatalError("The font \(name) is not available. Check Info.plist and make sure the font is included in all targets.")
        }

        return font
    }

    @objc static func light(size: CGFloat) -> UIFont {
        return font(named: "SFProDisplay-Light", size: size)
    }
    
    @objc static func regular(size: CGFloat) -> UIFont {
        return font(named: "SFProDisplay-Regular", size: size)
    }
    
    @objc static func semibold(size: CGFloat) -> UIFont {
        return font(named: "SFProDisplay-Semibold", size: size)
    }
    
    @objc static func bold(size: CGFloat) -> UIFont {
        return font(named: "SFProDisplay-Bold", size: size)
    }
    
    @objc static func medium(size: CGFloat) -> UIFont {
        return font(named: "SFProDisplay-Medium", size: size)
    }

    // MARK: Text Fonts

    @objc static func regularText(size: CGFloat) -> UIFont {
        return font(named: "SFUIText-Regular", size: size)
    }

    // MARK: Monospaced fonts

    @objc static func regularMonospaced(size: CGFloat) -> UIFont {
        return font(named: "SFMono-Regular", size: size)
    }

    @objc static func mediumMonospaced(size: CGFloat) -> UIFont {
        return font(named: "SFMono-Medium", size: size)
    }

    @objc static func semiboldMonospaced(size: CGFloat) -> UIFont {
        return font(named: "SFMono-Semibold", size: size)
    }

    @objc static func boldMonospaced(size: CGFloat) -> UIFont {
        return font(named: "SFMono-Bold", size: size)
    }
}
