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

class ConfirmationButton: UIControl {

    enum ContentState {
        case actionable
        case confirmation
    }

    static let height: CGFloat = 35
    let margin: CGFloat = 0

    var contentState: ContentState = .actionable {
        didSet {
            switch self.contentState {
            case .actionable:
                self.bottomConstraint.isActive = false
                self.topConstraint.isActive = true
            case .confirmation:
                self.topConstraint.isActive = false
                self.bottomConstraint.isActive = true
            }

            if self.contentState == .confirmation {
                self.isEnabled = false
            }

            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
                self.layoutIfNeeded()
            }, completion: { _ in
                self.isEnabled = self.contentState == .actionable

                if self.contentState == .confirmation {
                    DispatchQueue.main.asyncAfter(seconds: 1) {
                        self.contentState = .actionable
                    }
                }
            })
        }
    }

    private lazy var backgroundOverlay: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        view.isUserInteractionEnabled = false
        view.alpha = 0

        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 17)
        view.textColor = Theme.tintColor
        view.textAlignment = .center
        view.isUserInteractionEnabled = false

        return view
    }()

    private lazy var confirmationLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.semibold(size: 16)
        view.textColor = Theme.greyTextColor
        view.textAlignment = .center
        view.isUserInteractionEnabled = false

        return view
    }()

    private lazy var checkmarkImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.image = #imageLiteral(resourceName: "checkmark_big").withRenderingMode(.alwaysTemplate)
        view.tintColor = Theme.greyTextColor.withAlphaComponent(0.8)
        view.isUserInteractionEnabled = false

        return view
    }()

    private lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .light)
    }()

    private lazy var horizontalContainers: [UILayoutGuide] = {
        [UILayoutGuide(), UILayoutGuide()]
    }()

    private lazy var spacingContainers: [UILayoutGuide] = {
        [UILayoutGuide(), UILayoutGuide(), UILayoutGuide(), UILayoutGuide()]
    }()

    private lazy var topConstraint: NSLayoutConstraint = {
        self.horizontalContainers[0].topAnchor.constraint(equalTo: self.topAnchor)
    }()

    private lazy var bottomConstraint: NSLayoutConstraint = {
        self.horizontalContainers[1].bottomAnchor.constraint(equalTo: self.bottomAnchor)
    }()

    var title: String? {
        didSet {
            guard let title = self.title else { return }
            titleLabel.text = title
        }
    }

    var confirmation: String? {
        didSet {
            guard let confirmation = self.confirmation else { return }
            self.confirmationLabel.text = confirmation
        }
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = 4
        clipsToBounds = true

        addSubviewsAndConstraints()

        topConstraint.isActive = true
    }

    private func addSubviewsAndConstraints() {

        addSubview(backgroundOverlay)
        addSubview(titleLabel)
        addSubview(confirmationLabel)
        addSubview(checkmarkImageView)

        for container in horizontalContainers {
            addLayoutGuide(container)
        }

        for container in spacingContainers {
            addLayoutGuide(container)
        }

        NSLayoutConstraint.activate([
            self.backgroundOverlay.topAnchor.constraint(equalTo: self.topAnchor),
            self.backgroundOverlay.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.backgroundOverlay.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.backgroundOverlay.rightAnchor.constraint(equalTo: self.rightAnchor),

            self.horizontalContainers[0].leftAnchor.constraint(equalTo: self.leftAnchor),
            self.horizontalContainers[0].rightAnchor.constraint(equalTo: self.rightAnchor),
            self.horizontalContainers[0].heightAnchor.constraint(equalToConstant: ConfirmationButton.height),

            self.horizontalContainers[1].topAnchor.constraint(equalTo: self.horizontalContainers[0].bottomAnchor),
            self.horizontalContainers[1].leftAnchor.constraint(equalTo: self.leftAnchor),
            self.horizontalContainers[1].rightAnchor.constraint(equalTo: self.rightAnchor),
            self.horizontalContainers[1].heightAnchor.constraint(equalToConstant: ConfirmationButton.height),

            self.spacingContainers[0].topAnchor.constraint(equalTo: self.horizontalContainers[0].topAnchor),
            self.spacingContainers[0].leftAnchor.constraint(equalTo: self.horizontalContainers[0].leftAnchor),
            self.spacingContainers[0].bottomAnchor.constraint(equalTo: self.horizontalContainers[0].bottomAnchor),
            self.spacingContainers[0].widthAnchor.constraint(greaterThanOrEqualToConstant: self.margin),

            self.spacingContainers[1].topAnchor.constraint(equalTo: self.horizontalContainers[0].topAnchor),
            self.spacingContainers[1].rightAnchor.constraint(equalTo: self.horizontalContainers[0].rightAnchor),
            self.spacingContainers[1].bottomAnchor.constraint(equalTo: self.horizontalContainers[0].bottomAnchor),
            self.spacingContainers[1].widthAnchor.constraint(greaterThanOrEqualToConstant: self.margin),
            self.spacingContainers[1].widthAnchor.constraint(equalTo: self.spacingContainers[0].widthAnchor).priority(.defaultHigh),

            self.titleLabel.topAnchor.constraint(equalTo: self.horizontalContainers[0].topAnchor),
            self.titleLabel.leftAnchor.constraint(equalTo: self.spacingContainers[0].rightAnchor),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.horizontalContainers[0].bottomAnchor),
            self.titleLabel.rightAnchor.constraint(equalTo: self.spacingContainers[1].leftAnchor),

            self.spacingContainers[2].topAnchor.constraint(equalTo: self.horizontalContainers[1].topAnchor),
            self.spacingContainers[2].leftAnchor.constraint(equalTo: self.horizontalContainers[1].leftAnchor),
            self.spacingContainers[2].bottomAnchor.constraint(equalTo: self.horizontalContainers[1].bottomAnchor),
            self.spacingContainers[2].widthAnchor.constraint(greaterThanOrEqualToConstant: self.margin),

            self.spacingContainers[3].topAnchor.constraint(equalTo: self.horizontalContainers[1].topAnchor),
            self.spacingContainers[3].rightAnchor.constraint(equalTo: self.horizontalContainers[1].rightAnchor),
            self.spacingContainers[3].bottomAnchor.constraint(equalTo: self.horizontalContainers[1].bottomAnchor),
            self.spacingContainers[3].widthAnchor.constraint(greaterThanOrEqualToConstant: self.margin),
            self.spacingContainers[3].widthAnchor.constraint(equalTo: self.spacingContainers[2].widthAnchor).priority(.defaultHigh),

            self.confirmationLabel.topAnchor.constraint(equalTo: self.horizontalContainers[1].topAnchor),
            self.confirmationLabel.leftAnchor.constraint(equalTo: self.spacingContainers[2].rightAnchor),
            self.confirmationLabel.bottomAnchor.constraint(equalTo: self.horizontalContainers[1].bottomAnchor),

            self.checkmarkImageView.centerYAnchor.constraint(equalTo: self.horizontalContainers[1].centerYAnchor, constant: -1),
            self.checkmarkImageView.leftAnchor.constraint(equalTo: self.confirmationLabel.rightAnchor, constant: 3),
            self.checkmarkImageView.rightAnchor.constraint(equalTo: self.spacingContainers[3].leftAnchor),

            self.heightAnchor.constraint(equalToConstant: ConfirmationButton.height)
        ])
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted != oldValue {
                feedbackGenerator.impactOccurred()

                UIView.highlightAnimation {
                    self.backgroundOverlay.alpha = self.isHighlighted ? 1 : 0
                }
            }
        }
    }
}
