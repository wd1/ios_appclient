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

class ModalPresentationController: UIPresentationController {

    override func presentationTransitionWillBegin() {
        guard let rateUserController = self.presentedViewController as? ModalPresentable else { return }
        guard let containerView = self.containerView, let presentedView = self.presentedView else { return }

        containerView.addSubview(presentedView)
        rateUserController.background.alpha = 0

        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            rateUserController.background.alpha = 1
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        guard let rateUserController = self.presentedViewController as? ModalPresentable else { return }

        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            rateUserController.background.alpha = 0
        }, completion: nil)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        return containerView?.bounds ?? .zero
    }
}
