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

final class ModalTransition: NSObject, UIViewControllerAnimatedTransitioning {

    let operation: ControllerTransitionOperation

    var duration: TimeInterval {
        switch operation {
        case .present:
            return 0.8
        case .dismiss:
            return 0.4
        }
    }

    init(operation: ControllerTransitionOperation) {
        self.operation = operation
        super.init()
    }

    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch operation {
        case .present:
            present(with: transitionContext)
        case .dismiss:
            dismiss(with: transitionContext)
        }
    }

    func present(with context: UIViewControllerContextTransitioning) {
        guard let controller = context.viewController(forKey: UITransitionContextViewControllerKey.to) as? ModalPresentable else { return }
        controller.visualEffectView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        controller.visualEffectView.alpha = 0.5

        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
            controller.visualEffectView.alpha = 1
        }, completion: { didComplete in
            context.completeTransition(didComplete)
        })

        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 20, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
            controller.visualEffectView.transform = .identity
        }, completion: nil)
    }

    func dismiss(with context: UIViewControllerContextTransitioning) {
        guard let controller = context.viewController(forKey: UITransitionContextViewControllerKey.from) as? ModalPresentable else { return }

        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeInFromCurrentStateWithUserInteraction, animations: {
            controller.visualEffectView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            controller.visualEffectView.alpha = 0
        }, completion: { didComplete in
            context.completeTransition(didComplete)
        })
    }
}
