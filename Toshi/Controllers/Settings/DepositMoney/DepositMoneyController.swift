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
import TinyConstraints

class DepositMoneyController: UIViewController {

    private var items: [DepositMoneyItem] = []

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.alwaysBounceVertical = true
        view.showsVerticalScrollIndicator = true
        view.delaysContentTouches = false
        view.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 40, right: 0)

        return view
    }()

    private lazy var stackView: UIStackView = UIStackView(with: self.items)

    convenience init(for username: String, name _: String) {
        self.init(nibName: nil, bundle: nil)

        title = Localized("deposit_money_title")

        items = [
            .header(Localized("deposit_money_header_text")),
            .bulletPoint(Localized("deposit_money_1_title"), String(format: Localized("deposit_money_1_text"), Cereal.shared.paymentAddress)),
            .copyToClipBoard(Localized("copy_to_clipboard_action"), Localized("copy_to_clipboard_feedback"), #selector(copyToClipBoard(_:))),
            .QRCode(Cereal.shared.walletAddressQRCodeImage(resizeRate: 20.0)),
            .bulletPoint(Localized("deposit_money_2_title"), Localized("deposit_money_2_text")),
            .bulletPoint(Localized("deposit_money_3_title"), Localized("deposit_money_3_text")),
            .bulletPoint(Localized("deposit_money_4_title"), Localized("deposit_money_4_text"))
        ]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.lightGrayBackgroundColor

        view.addSubview(scrollView)
        scrollView.edges(to: view)

        scrollView.addSubview(stackView)
        stackView.edges(to: scrollView)
        stackView.width(to: scrollView)

    }
    
    @objc func copyToClipBoard(_ button: ConfirmationButton) {
        copyStringToClipboard(Cereal.shared.paymentAddress,
                              thenUpdate: button)
    }
}

extension DepositMoneyController: ClipboardCopying { /* mix-in */ }
