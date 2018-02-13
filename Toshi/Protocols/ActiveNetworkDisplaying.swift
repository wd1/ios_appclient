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
import SweetUIKit

protocol ActiveNetworkDisplaying: class {
    var activeNetworkView: ActiveNetworkView { get }
    var activeNetworkViewConstraints: [NSLayoutConstraint] { get }

    func setupActiveNetworkView(hidden: Bool)
    func defaultActiveNetworkView() -> ActiveNetworkView
    func showActiveNetworkViewIfNeeded()
    func hideActiveNetworkViewIfNeeded()

    func requestLayoutUpdate()
}

extension ActiveNetworkDisplaying where Self: UIViewController {
    func setupActiveNetworkView(hidden: Bool = false) {
        guard let activeNetworkView = self.activeNetworkView as ActiveNetworkView? else { return }

        view.addSubview(activeNetworkView)
        NSLayoutConstraint.activate(activeNetworkViewConstraints)

        if !hidden {
            showActiveNetworkViewIfNeeded()
        }
    }

    func defaultActiveNetworkView() -> ActiveNetworkView {
        let activeNetworkView = ActiveNetworkView(withAutoLayout: true)

        return activeNetworkView
    }

    func showActiveNetworkViewIfNeeded() {
        guard !NetworkSwitcher.shared.isDefaultNetworkActive && activeNetworkView.heightConstraint?.constant != ActiveNetworkView.height else { return }

        DispatchQueue.main.async {
            self.activeNetworkView.heightConstraint?.constant = ActiveNetworkView.height
            self.requestLayoutUpdate()
        }
    }

    func hideActiveNetworkViewIfNeeded() {
        guard !NetworkSwitcher.shared.isDefaultNetworkActive else { return }

        DispatchQueue.main.async {
            self.activeNetworkView.heightConstraint?.constant = 0
            self.requestLayoutUpdate()
        }
    }

    func requestLayoutUpdate() {
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
}
