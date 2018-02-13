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

protocol AcceptDeclineButtonsViewDelegate: class {
    func didSelectAccept()
    func didSelectDecline()
}

final class AcceptDeclineButtonsView: UIView {
    
    weak var delegate: AcceptDeclineButtonsViewDelegate?

    private lazy var acceptButton: ChatButton = {
        let acceptButton = ChatButton()
        acceptButton.title = Localized("accept_button_title")
        acceptButton.addTarget(self, action: #selector(didSelectAccept), for: .touchUpInside)
        acceptButton.leftImage = UIImage(named: "approve_icon")?.withRenderingMode(.alwaysTemplate)

        return acceptButton
    }()

    private lazy var declineButton: ChatButton = {
        let declineButton = ChatButton()
        declineButton.title = Localized("decline_button_title")
        declineButton.addTarget(self, action: #selector(didSelectDecline), for: .touchUpInside)
        declineButton.leftImage = UIImage(named: "decline_icon")?.withRenderingMode(.alwaysTemplate)

        declineButton.setTintColor(Theme.inactiveButtonColor)

        return declineButton
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white

        addSubview(acceptButton)
        addSubview(declineButton)

        acceptButton.top(to: self, offset: 7.5)
        acceptButton.left(to: self, offset: 4)
        acceptButton.bottom(to: self, offset: -10)

        declineButton.top(to: self, offset: 7.5)
        declineButton.leftToRight(of: acceptButton, offset: 4)
        declineButton.right(to: self, offset: -4)
        declineButton.bottom(to: self, offset: -10)

        acceptButton.width(to: declineButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectAccept() {
        delegate?.didSelectAccept()
    }

    @objc private func didSelectDecline() {
        delegate?.didSelectDecline()
    }
}
