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
import CoreImage

class QRCodeController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private lazy var qrCodeImageView: UIImageView = UIImageView()

    private lazy var subtitleLabel = TextLabel(Localized("profile_qr_code_subtitle"))

    convenience init(for username: String, name: String) {
        self.init(nibName: nil, bundle: nil)

        title = Localized("profile_qr_code_title")

        qrCodeImageView.image = QRCodeGenerator.qrCodeImage(for: .addUser(username: username))
    }

    override func loadView() {
        let scrollView = UIScrollView()

        view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Theme.lightGrayBackgroundColor
        
        let contentView = UIView()
        view.addSubview(contentView)

        contentView.edges(to: view)
        contentView.width(to: view)
        contentView.height(to: layoutGuide(), relation: .equalOrGreater)
        
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(qrCodeImageView)

        subtitleLabel.top(to: contentView, offset: 13)
        subtitleLabel.left(to: view, offset: 20)
        subtitleLabel.right(to: view, offset: -20)

        let qrCodeTopLayoutGuide = UILayoutGuide()
        contentView.addLayoutGuide(qrCodeTopLayoutGuide)

        qrCodeTopLayoutGuide.topToBottom(of: subtitleLabel)
        qrCodeTopLayoutGuide.height(40, relation: .equalOrGreater)
        qrCodeTopLayoutGuide.left(to: contentView)
        qrCodeTopLayoutGuide.right(to: contentView)

        qrCodeImageView.topToBottom(of: qrCodeTopLayoutGuide)
        qrCodeImageView.height(300)
        qrCodeImageView.width(300)
        qrCodeImageView.centerX(to: contentView)
        
        let qrCodeBottomLayoutGuide = UILayoutGuide()
        contentView.addLayoutGuide(qrCodeBottomLayoutGuide)

        qrCodeBottomLayoutGuide.topToBottom(of: qrCodeImageView)
        qrCodeBottomLayoutGuide.left(to: contentView)
        qrCodeBottomLayoutGuide.right(to: contentView)
        qrCodeBottomLayoutGuide.bottom(to: contentView)
        qrCodeBottomLayoutGuide.height(to: qrCodeTopLayoutGuide)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(true)
    }
}

extension QRCodeController: UIToolbarDelegate {

    func position(for _: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
