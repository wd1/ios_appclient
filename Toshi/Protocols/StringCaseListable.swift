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

/// A protocol to allow grabbing an array of all the cases of a string enum.
/// Inspired by: http://stackoverflow.com/a/32429125/681493
protocol StringCaseListable {
    /// - parameter rawValue: The raw string value. Matches the initializer of RawRepresentable without the Self restrictions.
    init?(rawValue: String)
}

// MARK: - Default Implementation
extension StringCaseListable {
    
    /// - returns: A generated array of all the cases in this enum.
    static var allCases: [Self] {
        var caseIndex: Int = 0
        let generator: AnyIterator<Self> = AnyIterator {
            let current: Self = withUnsafePointer(to: &caseIndex) {
                $0.withMemoryRebound(to: Self.self, capacity: 1) { $0.pointee }
            }
            caseIndex += 1
            return current
        }
        return Array(generator)
    }
}
