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
import CameraScanner

class ScannerController: ScannerViewController {

    var isStatusBarHidden = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupActivityIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private lazy var activityView: UIActivityIndicatorView = {
        self.defaultActivityIndicator()
    }()

    override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }

    override func setupToolbarItems() {
        toolbar.setItems([self.cancelItem], animated: true)
    }

    func setStatusBarHidden() {
        isStatusBarHidden = true
        setNeedsStatusBarAppearanceUpdate()
    }
}

extension ScannerController: ActivityIndicating {

    var activityIndicator: UIActivityIndicatorView {
        return activityView
    }
}
