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

// MARK: - Delegate

protocol SegmentedHeaderDelegate: class {
    func segmentedHeader(_: SegmentedHeaderView, didSelectSegmentAt index: Int)
}

// MARK: - Segmented Header View

/// A custom header view for showing multiple segments, with an indicator of which is selected.

final class SegmentedHeaderView: UIView {

    private weak var delegate: SegmentedHeaderDelegate?
    private let segmentNames: [String]

    private var indicatorLeadingConstraint: NSLayoutConstraint!

    private lazy var indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.tintColor

        return view
    }()

    private lazy var segmentButtons: [UIButton] = {
        return segmentNames.map { name in
            let button = UIButton()
            button.titleLabel?.font = Theme.preferredSemibold()
            button.setTitleColor(Theme.tintColor, for: .selected)
            button.setTitleColor(Theme.tintColor, for: .highlighted)
            button.setTitleColor(Theme.lightGreyTextColor, for: .normal)
            button.setTitle(name, for: .normal)
            button.addTarget(self, action: #selector(tappedSegmentButton(_:)), for: .touchUpInside)

            return button
        }
    }()

    /// The current selected index of this control
    var selectedIndex: Int {
        return segmentButtons.index(where: { $0.isSelected }) ?? 0
    }

    // MARK: - Initialization

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - segmentNames: The titles for the various segment buttons. NOTE: There must be at least two or this will fatal error.
    ///   - delegate: The delegate to notify of selection.
    ///   - showsBottomBorder: True to have a border view at the bottom of the entire view, false not to. Defaults to true.
    init(segmentNames: [String], delegate: SegmentedHeaderDelegate, showsBottomBorder: Bool = true) {

        self.segmentNames = segmentNames
        self.delegate = delegate
        super.init(frame: .zero)

        if showsBottomBorder {
            setupBottomBorder()
        }

        guard segmentNames.count > 1 else {
            fatalError("You can't create this without at least two segments, or all the math is gonna be pretty screwy")
        }

        let widthProportion = CGFloat(1) / CGFloat(segmentNames.count)

        setupIndicatorView(widthProportion: widthProportion)
        setupSegmentButtons(widthProportion: widthProportion)

        selectIndex(0, animated: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Setup

    private func setupBottomBorder() {
        let border = BorderView()
        addSubview(border)

        border.addHeightConstraint()
        border.edgesToSuperview(excluding: .top)
    }

    private func setupSegmentButtons(widthProportion: CGFloat) {
        for (index, button) in segmentButtons.enumerated() {
            addSubview(button)

            switch index {
            case 0: // first button
                button.leadingToSuperview()
            case (segmentButtons.count - 1): // Last button
                let previousButton = segmentButtons[index - 1]
                button.leadingToTrailing(of: previousButton)
                button.trailingToSuperview()
            default: // Somewhere in the middle
                let previousButton = segmentButtons[index - 1]
                button.leadingToTrailing(of: previousButton)
            }

            button.top(to: self)
            button.bottom(to: self)
            button.width(to: self, multiplier: widthProportion)
        }
    }

    private func setupIndicatorView(widthProportion: CGFloat) {
        addSubview(indicatorView)

        indicatorLeadingConstraint = indicatorView.leadingToSuperview()

        indicatorView.width(to: self, multiplier: widthProportion)
        indicatorView.height(2)
        indicatorView.bottomToSuperview()
    }

    // MARK: - Action Handling

    @objc private func tappedSegmentButton(_ button: UIButton) {
        guard let index = segmentButtons.index(of: button) else {
            assertionFailure("Tapped button doesn't exist in list of segment buttons")
            return
        }

        selectIndex(index)
        delegate?.segmentedHeader(self, didSelectSegmentAt: index)
    }

    // MARK: - Animation

    private func moveIndicator(below index: Int, animated: Bool = true) {
        // Perform any other layout in progress so animation only shows this change
        layoutIfNeeded()

        switch index {
        case 0:
            // Math not necessary, just put it all the way to the leading edge.
            indicatorLeadingConstraint.constant = 0
        default:
            // Calculate where it needs to go.
            let buttonWidth = frame.width / CGFloat(segmentButtons.count)
            indicatorLeadingConstraint.constant = buttonWidth * CGFloat(index)
        }

        UIView.animate(withDuration: animated ? 0.15 : 0,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
                        self.layoutIfNeeded()
        })
    }

    // MARK: - Public API

    /// Selects a segment at a given index.
    ///
    /// - Parameters:
    ///   - index: The index to select
    ///   - animated: Whether or not you want this change animated. Defaults to true.
    func selectIndex(_ index: Int, animated: Bool = true) {
        segmentButtons.forEach { $0.isSelected = false }
        segmentButtons[index].isSelected = true
        moveIndicator(below: index, animated: animated)
    }

    /// Selects a segment based on its title, regardless of its index in the view.
    ///
    /// - Parameters:
    ///   - title: The title of the item to select. Note that if the title is not in the list of segment names, there will be an assertion failure.
    ///   - animated: Whether or not you want the selection to be animated. Defaults to true.
    func selectItem(_ title: String, animated: Bool = true) {
        guard let index = segmentNames.index(of: title) else {
            assertionFailure("No item in this control titled \(title)")
            return
        }

        selectIndex(index, animated: animated)
    }
}
