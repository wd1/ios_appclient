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

enum Mode: Int {
    case localUser, remoteUser

    var remoteModePriority: UILayoutPriority {
        switch self {
        case .localUser:
            return .defaultLow
        case .remoteUser:
            return .defaultHigh
        }
    }

    var localModePriority: UILayoutPriority {
        switch self {
        case .remoteUser:
            return .defaultLow
        case .localUser:
            return .defaultHigh
        }
    }
}

final class PaymentRequestInfoView: UIView {

    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var userAvatarImageView: UIImageView!
    @IBOutlet private(set) weak var userDisplayNameLabel: UILabel!
    @IBOutlet private(set) weak var userNameLabel: UILabel!
    @IBOutlet private(set) weak var ratingView: RatingView!
    @IBOutlet private(set) weak var ratingCountLabel: UILabel!
    @IBOutlet private(set) weak var valueLabel: UILabel!

    @IBOutlet var remoteUserModeConstraints: [NSLayoutConstraint]!
    @IBOutlet var localUserModeConstraints: [NSLayoutConstraint]!

    var mode: Mode = .remoteUser {
        didSet {
            self.updateConstraintsPriority()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        userAvatarImageView.layer.cornerRadius = 22.0
        userAvatarImageView.layer.masksToBounds = true
    }

    private func updateConstraintsPriority() {
        for constraint in remoteUserModeConstraints {
            constraint.priority = mode.remoteModePriority
        }

        for constraint in localUserModeConstraints {
            constraint.priority = mode.localModePriority
        }

        setNeedsLayout()

        ratingView.isHidden = mode == .remoteUser
        ratingCountLabel.isHidden = mode == .remoteUser
    }
}
