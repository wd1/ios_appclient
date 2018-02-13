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

protocol DisappearingBackgroundNavBarDelegate: class {
    
    func didTapLeftButton(in navBar: DisappearingBackgroundNavBar)
    func didTapRightButton(in navBar: DisappearingBackgroundNavBar)
}

/// A view to allow a fake nav bar that can appear and disappear as the user scrolls, but allowing its buttons to stay in place.
final class DisappearingBackgroundNavBar: UIView {
    
    private let interItemSpacing: CGFloat = 8
    
    weak var delegate: DisappearingBackgroundNavBarDelegate?

    private static let containerHeight: CGFloat = 44

    static var defaultHeight: CGFloat {
        if #available(iOS 11, *) {
            return DisappearingBackgroundNavBar.containerHeight
        } else {
            // Take the status bar into account
            return DisappearingBackgroundNavBar.containerHeight + 20
        }
    }

    private var titleCenterYConstraint: NSLayoutConstraint?

    var heightConstraint: NSLayoutConstraint?
    
    private lazy var leftButton: UIButton = {
        let button = UIButton(withAutoLayout: true)
        button.tintColor = Theme.tintColor
        button.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)

        return button
    }()
    
    private lazy var rightButton: UIButton = {
        let button = UIButton(withAutoLayout: true)
        button.tintColor = Theme.tintColor
        button.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(withAutoLayout: false)
        label.font = Theme.preferredSemibold()
        label.textAlignment = .center
        
        return label
    }()
    
    private lazy var backgroundView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = .white
        view.clipsToBounds = true
        
        let bottomBorder = BorderView()
        view.addSubview(bottomBorder)
        bottomBorder.edgesToSuperview(excluding: .top)
        bottomBorder.addHeightConstraint()
        
        return view
    }()

    private lazy var bottomBorder = BorderView()
    
    // MARK: - Initialization
    
    convenience init(delegate: DisappearingBackgroundNavBarDelegate?) {
        self.init(frame: .zero)
        self.delegate = delegate
        
        setupBackground()
        setupButtonAndTitleContainer()
    }
    
    private func setupBackground() {
        addSubview(backgroundView)
        
        backgroundView.edgesToSuperview()
        backgroundView.alpha = 0
    }

    private func setupButtonAndTitleContainer() {
        let container = UIView(withAutoLayout: false)
        container.backgroundColor = .clear

        addSubview(container)
        container.edgesToSuperview(excluding: .top)
        container.height(DisappearingBackgroundNavBar.containerHeight)

        setupLeftButton(in: container)
        setupRightButton(in: container)
        setupTitleLabel(in: container, leftButton: leftButton, rightButton: rightButton)
    }
    
    private func setupLeftButton(in view: UIView) {
        view.addSubview(leftButton)
        
        leftButton.leftToSuperview(offset: interItemSpacing)
        leftButton.centerYToSuperview()
        leftButton.setContentHuggingPriority(.required, for: .horizontal)
        leftButton.width(min: .defaultButtonHeight)
        leftButton.height(min: .defaultButtonHeight)
        
        leftButton.isHidden = true
    }
    
    private func setupRightButton(in view: UIView) {
        view.addSubview(rightButton)
        
        rightButton.rightToSuperview(offset: interItemSpacing)
        rightButton.centerYToSuperview()
        rightButton.setContentHuggingPriority(.required, for: .horizontal)
        rightButton.width(min: .defaultButtonHeight)
        rightButton.height(min: .defaultButtonHeight)
        
        rightButton.isHidden = true
    }
    
    private func setupTitleLabel(in view: UIView, leftButton: UIButton, rightButton: UIButton) {
        view.addSubview(titleLabel)
        
        titleCenterYConstraint = titleLabel.centerYToSuperview()
        titleLabel.leftToRight(of: leftButton, offset: interItemSpacing)
        titleLabel.rightToLeft(of: rightButton, offset: interItemSpacing)
        titleLabel.centerXToSuperview()

        titleLabel.alpha = 0
    }

    // MARK: - Button Images
    
    /// Sets up the left button to appear to be a back button.
    func setupLeftAsBackButton() {
        setLeftButtonImage(#imageLiteral(resourceName: "navigation_back"), accessibilityLabel: Localized("nav_bar_back"))
    }
    
    /// Takes an image, turns it into an always-template image, then sets it to the left button and un-hides the left button.
    ///
    /// - Parameters:
    ///   - image: The image to set on the left button as a template image.
    ///   - accessibilityLabel: The accessibility label which should be read to voice over users describing the left button.
    func setLeftButtonImage(_ image: UIImage, accessibilityLabel: String) {
        let templateImage = image.withRenderingMode(.alwaysTemplate)
        leftButton.setImage(templateImage, for: .normal)
        leftButton.accessibilityLabel = accessibilityLabel
        leftButton.isHidden = false
        
        let imageWidth = image.size.width
        let differenceFromDefault = .defaultButtonHeight - imageWidth
        if differenceFromDefault > 0 {
            leftButton.imageEdgeInsets = UIEdgeInsets(top: 0,
                                                      left: -differenceFromDefault,
                                                      bottom: 0,
                                                      right: 0)
        }
    }
    
    /// Takes an image, turns it into an always-template image, then sets it to the right button and un-hides the right button.
    ///
    /// - Parameters:
    ///   - image: The image to set on the right button as a template image.
    ///   - accessibilityLabel: The accessibility label which should be read to voice over users describing the right button.
    func setRightButtonImage(_ image: UIImage, accessibilityLabel: String) {
        let templateImage = image.withRenderingMode(.alwaysTemplate)
        rightButton.setImage(templateImage, for: .normal)
        rightButton.isHidden = false
        rightButton.accessibilityLabel = accessibilityLabel
        
        let imageWidth = image.size.width
        let differenceFromDefault = .defaultButtonHeight - imageWidth
        if differenceFromDefault > 0 {
            rightButton.imageEdgeInsets = UIEdgeInsets(top: 0,
                                                       left: 0,
                                                       bottom: 0,
                                                       right: -differenceFromDefault)
        }
    }
    
    /// Sets a string as the title. Does *not* automatically show it.
    ///
    /// - Parameter text: The text to set as the title.
    func setTitle(_ text: String) {
        titleLabel.text = text
    }
    
    // MARK: - Show/Hide

    /// Makes both title and background immediately visible. Useful when the bar should always be shown.
    func showTitleAndBackground() {
        setAlpha(1, on: [titleLabel, backgroundView])
    }

    func setBackgroundAlpha(_ alpha: CGFloat) {
        setAlpha(alpha, on: [backgroundView])
    }

    func setTitleAlpha(_ alpha: CGFloat) {
        setAlpha(alpha, on: [titleLabel])
    }

    private func setAlpha(_ alpha: CGFloat, on views: [UIView]) {
        for view in views {
            view.alpha = alpha
        }
    }

    /// Sets the title offset based on how much of a target view has been scrolled past the bottom of the bar.
    ///
    /// - Parameter scrollPastPercentage: The percentage of the target view which has been scrolled past the bottom of the bar. Should be between 0 and 1.
    func setTitleOffsetPercentage(from scrollPastPercentage: CGFloat) {
        guard let constraint = titleCenterYConstraint else { /* not set up yet */ return }

        let containerHeight = DisappearingBackgroundNavBar.containerHeight
        let titleHeight = titleLabel.frame.height
        let minAboveNav: CGFloat = 4 // per Marek

        let minOffset: CGFloat = 0
        let maxOffset = ((containerHeight - titleHeight) / 2) - minAboveNav
        let offsetDelta = maxOffset - minOffset

        switch scrollPastPercentage {
        case 0: // We have not scrolled past the title at all, it shouldn't be visible.
            constraint.constant = maxOffset
        case 1: // We have totally scrolled past the title, it should be visible.
            constraint.constant = minOffset
        default: // Somewhere in the middle.
            constraint.constant = maxOffset - (offsetDelta * scrollPastPercentage)
        }
    }

    // MARK: - Action Targets
    
    @objc private func leftButtonTapped() {
        guard let delegate = delegate else {
            assertionFailure("You probably want a delegate here")
            
            return
        }
        
        delegate.didTapLeftButton(in: self)
    }
    
    @objc private func rightButtonTapped() {
        guard let delegate = delegate else {
            assertionFailure("You probably want a delegate here")
            
            return
        }
        
        delegate.didTapRightButton(in: self)
    }
}
