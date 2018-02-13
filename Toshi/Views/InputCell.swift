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

protocol InputCellUpdater: class {
    func inputDidUpdate(_ detailText: String?, _ switchMode: Bool)
}

final class InputCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet private(set) weak var textField: UITextField!

    @IBOutlet weak var switchControl: UISwitch!
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var titleWidthConstraint: NSLayoutConstraint?

    var updater: InputCellUpdater?

    override func awakeFromNib() {
        super.awakeFromNib()

        textField.textColor = Theme.greyTextColor
        textField.delegate = self
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        textField.isHidden = false
        switchControl.isHidden = true

        textField.text = nil
        titleLabel.text = nil
        switchControl.isOn = false
    }

    @objc @IBAction private func switchValueDidChange(_: Any) {
        updater?.inputDidUpdate(textField.text, switchControl.isOn)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        updater?.inputDidUpdate(text, switchControl.isOn)

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }
}
