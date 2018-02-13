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

/// SOFA::Status:{
//      "type": "added",
//      "subject": "Robert"
//      "object": "Marek"
//  }
final class SofaStatus: SofaWrapper {
    enum StatusType: String {
        case created
        case becameMember
        case leave
        case added
        case changePhoto
        case rename
        case setToPublic
        case setToPrivate
        case none
    }

    override var type: SofaType {
        return .status
    }

    var statusType: StatusType = .none
    // The types of the object and subjects of the action will probably be user id's int he end
    var subject: String?
    var object: String?

    var attributedText: NSAttributedString?

    override init(content: String) {
        super.init(content: content)

        if let statusJSON = json["type"] as? String {
            self.statusType = StatusType(rawValue: statusJSON) ?? .none
        }

         self.subject = json["subject"] as? String
         self.object = json["object"] as? String

        self.attributedText = getAttributedText()
    }

    func getAttributedText() -> NSAttributedString? {
        guard let subject = subject else { return nil }

        switch statusType {
        case .created:
            return attributedString(for: Localized("status_type_create"), with: [""])
        case .becameMember:
            return attributedString(for: Localized("status_type_became_member"), with: [subject])
        case .leave:
            return attributedString(for: Localized("status_type_leave"), with: [subject])
        case .added:
            guard let object = object else { return nil }
            return attributedString(for: Localized("status_type_added"), with: [subject, object])
        case .changePhoto:
            return attributedString(for: Localized("status_type_change_photo"), with: [subject])
        case .rename:
            guard let object = object else { return nil }
            return attributedString(for: Localized("status_type_rename"), with: [subject, object])
        case .setToPublic:
            return attributedString(for: Localized("status_type_make_public"), with: [subject])
        case .setToPrivate:
            return attributedString(for: Localized("status_type_make_private"), with: [subject])
        default:
            return nil
        }
    }

    private func attributedString(for string: String, with boldStrings: [String]) -> NSAttributedString {
        let string = String(format: string, arguments: boldStrings)
        let attributedString = NSMutableAttributedString(string: string)

        let normalAttributes = [NSAttributedStringKey.font: Theme.preferredFootnote()]
        attributedString.addAttributes(normalAttributes, range: string.nsRange(forSubstring: string))
        let boldAttributes = [NSAttributedStringKey.font: Theme.preferredFootnoteBold()]

        for boldString in boldStrings {
            attributedString.addAttributes(boldAttributes, range: string.nsRange(forSubstring: boldString))
        }

        return attributedString
    }
}
