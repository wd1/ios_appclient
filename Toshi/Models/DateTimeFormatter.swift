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

struct DateTimeFormatter {
    static var oneDayTimeInterval: TimeInterval = 60 * 60 * 24

    static var oneWeekTimeInterval: TimeInterval = 60 * 60 * 24 * 7

    static var dateFormatter: DateFormatter {
        let dt = DateFormatter()
        dt.locale = Locale.current
        dt.timeStyle = .none
        dt.dateStyle = .short

        return dt
    }

    static var weekdayFormatter: DateFormatter {
        let dt = DateFormatter()
        dt.locale = Locale.current
        dt.dateFormat = "EEEE"

        return dt
    }

    static var timeFormatter: DateFormatter {
        let dt = DateFormatter()
        dt.locale = Locale.current
        dt.timeStyle = .short
        dt.dateStyle = .none

        return dt
    }

    static func dateOlderThanOneDay(date: Date) -> Bool {
        return Date().timeIntervalSince(date) > oneDayTimeInterval
    }

    static func dateOlderThanOneWeek(date: Date) -> Bool {
        return Date().timeIntervalSince(date) > oneWeekTimeInterval
    }

    static func isDate(_ date: Date, sameDayAs anotherDate: Date) -> Bool {
        let componentFlags: Set<Calendar.Component> = [.year, .month, .day]
        let components1 = Calendar.autoupdatingCurrent.dateComponents(componentFlags, from: date)
        let components2 = Calendar.autoupdatingCurrent.dateComponents(componentFlags, from: anotherDate)

        return (components1.year == components2.year) && (components1.month == components2.month) && (components1.day == components2.day)
    }
}
