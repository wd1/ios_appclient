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

class AdvancedSettingsController: UITableViewController {

    @IBOutlet private weak var networkNameLabel: UILabel!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(false)
    }
}

extension AdvancedSettingsController {

    override func tableView(_: UITableView, willDisplayFooterView view: UIView, forSection _: Int) {
        guard let footerView = view as? UITableViewHeaderFooterView else { return }

        footerView.textLabel?.text = Localized("settings_advanced_network_change_warning")
    }

    override func tableView(_: UITableView, didSelectRowAt _: IndexPath) {
        navigationController?.pushViewController(NetworkSettingsController(), animated: true)
    }
}
