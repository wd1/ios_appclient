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

extension YapDatabaseViewConnection {
    func getChangesFor(notifications: [Notification], with mappings: YapDatabaseViewMappings) -> (rowChanges: [YapDatabaseViewRowChange], sectionChanges: [YapDatabaseViewSectionChange]) {
        var messageRowChanges = NSArray()
        var sectionChanges = NSArray()

        self.getSectionChanges(&sectionChanges, rowChanges: &messageRowChanges, for: notifications, with: mappings)

        //swiftlint:disable force_cast
        //the arrays returned from this obj-C method are definitely containing these Yap objects.
        let yapDatabaseViewRowChange = messageRowChanges as! [YapDatabaseViewRowChange]
        let yapDatabaseViewSectionChange = sectionChanges as! [YapDatabaseViewSectionChange]
        //swiftlint:enable force_cast

        return (rowChanges: yapDatabaseViewRowChange, sectionChanges: yapDatabaseViewSectionChange)
    }
}
