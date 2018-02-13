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

final class SofaMessage: SofaWrapper {

    class Button: Equatable {

        enum ControlType: String {
            case button
            case group
        }

        var type: ControlType = .button

        var label: String?

        // values are to be sent back as SofaCommands
        var value: Any?

        // Actions are to be handled locally.
        var action: Any?

        var subcontrols: [Button] = []

        init(json: [String: Any]) {
            if let jsonType = json["type"] as? String {
                type = ControlType(rawValue: jsonType) ?? .button
            }

            label = json["label"] as? String

            switch type {
            case .button:
                if let value = json["value"] {
                    self.value = value
                }
                if let action = json["action"] {
                    self.action = action
                }
            case .group:
                guard let controls = json["controls"] as? [[String: Any]] else { return }
                subcontrols = controls.map { (control) -> Button in
                    return Button(json: control)
                }
            }
        }

        static func == (lhs: SofaMessage.Button, rhs: SofaMessage.Button) -> Bool {
            let lhv = lhs.value as AnyObject
            let rhv = rhs.value as AnyObject
            let lha = lhs.action as AnyObject
            let rha = rhs.action as AnyObject

            return lhs.label == rhs.label && lhs.type == rhs.type && lhv === rhv && lha === rha
        }
    }

    override var type: SofaType {
        return .message
    }

    var showKeyboard: Bool? {
        return json["showKeyboard"] as? Bool
    }

    lazy var body: String = {
        self.json["body"] as? String ?? ""
    }()

    lazy var buttons: [SofaMessage.Button] = {
        // [{"type": "button", "label": "Red Cross", "value": "red-cross"},…]
        var buttons = [Button]()
        if let controls = self.json["controls"] as? [[String: Any]] {

            for control in controls {
                buttons.append(Button(json: control))
            }
        }

        return buttons
    }()

    convenience init(body: String) {
        self.init(content: ["body": body])
    }
}
