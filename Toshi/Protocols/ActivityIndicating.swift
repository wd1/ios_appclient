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

protocol ActivityIndicating: class {
    var activityIndicator: UIActivityIndicatorView { get }
    func defaultActivityIndicator() -> UIActivityIndicatorView

    func setupActivityIndicator()
    func showActivityIndicator()
    func hideActivityIndicator()
}

extension ActivityIndicating where Self: UIViewController {

    func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        self.activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    func defaultActivityIndicator() -> UIActivityIndicatorView {
        // need to initialize with large style which is available only white, thus need to set color later
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.color = Theme.lightGreyTextColor
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        return activityIndicator
    }

    func showActivityIndicator() {
        view.bringSubview(toFront: activityIndicator)
        activityIndicator.startAnimating()
    }

    func hideActivityIndicator() {
        view.sendSubview(toBack: activityIndicator)
        activityIndicator.stopAnimating()
    }
}
