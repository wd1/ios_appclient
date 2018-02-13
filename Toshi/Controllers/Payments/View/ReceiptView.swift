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

final class ReceiptView: UIStackView {

    private lazy var fiatAmountLine: ReceiptLineView = {
        let amountLine = ReceiptLineView()
        amountLine.setTitle(Localized("confirmation_amount"))

        return amountLine
    }()

    private lazy var estimatedNetworkFeesLine: ReceiptLineView = {
        let estimatedNetworkFeesLine = ReceiptLineView()
        estimatedNetworkFeesLine.setTitle(Localized("confirmation_estimated_network_fees"))

        return estimatedNetworkFeesLine
    }()

    private lazy var totalLine: ReceiptLineView = {
        let totalLine = ReceiptLineView()
        totalLine.setTitle(Localized("confirmation_total"))

        return totalLine
    }()

    private lazy var ethereumAmountLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredFootnote()
        view.textColor = Theme.lightGreyTextColor
        view.textAlignment = .right
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        axis = .vertical
        alignment = .center

        addWithDefaultConstraints(view: fiatAmountLine)
        addSpacing(.mediumInterItemSpacing, after: fiatAmountLine)

        addWithDefaultConstraints(view: estimatedNetworkFeesLine)
        addSpacing(.largeInterItemSpacing, after: estimatedNetworkFeesLine)

        let separator = BorderView()
        addWithDefaultConstraints(view: separator)
        separator.addHeightConstraint()

        addSpacing(.largeInterItemSpacing, after: separator)
        addWithDefaultConstraints(view: totalLine)
        addSpacing(7, after: totalLine)

        addWithDefaultConstraints(view: ethereumAmountLabel)
        addSpacing(.mediumInterItemSpacing, after: ethereumAmountLabel)

        // Add blank text to the ethereum label so there's not a jump in size when it loads
        ethereumAmountLabel.text = " "
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPaymentInfo(_ paymentInfo: PaymentInfo) {
        fiatAmountLine.setValue(paymentInfo.fiatString)
        estimatedNetworkFeesLine.setValue(paymentInfo.estimatedFeesString)
        totalLine.setValue(paymentInfo.totalFiatString)
        ethereumAmountLabel.text = paymentInfo.totalEthereumString
    }
}
