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

public final class TableSectionData {

    var tag: Int = 0

    var headerTitle = ""
    var footerTitle = ""

    var cellsData: [TableCellData]

    init(cellsData: [TableCellData] = [], headerTitle: String = "", footerTitle: String = "") {
        self.cellsData = cellsData
        self.headerTitle = headerTitle
        self.footerTitle = footerTitle
    }
}

public struct TableCellDataComponents: OptionSet {

    public let rawValue: Int

    public init(rawValue: Int) { self.rawValue = rawValue }

    static let title = TableCellDataComponents(rawValue: 1 << 0)
    static let subtitle = TableCellDataComponents(rawValue: 1 << 1)
    static let details = TableCellDataComponents(rawValue: 1 << 2)
    static let leftImage = TableCellDataComponents(rawValue: 1 << 3)
    static let switchControl = TableCellDataComponents(rawValue: 1 << 4)
    static let doubleImage = TableCellDataComponents(rawValue: 1 << 5)
    static let doubleAction = TableCellDataComponents(rawValue: 1 << 6)
    static let badge = TableCellDataComponents(rawValue: 1 << 7)
    static let topDetails = TableCellDataComponents(rawValue: 1 << 8)

    static let titleSubtitle: TableCellDataComponents = [.title, .subtitle]
    static let titleLeftImage: TableCellDataComponents = [.title, .leftImage]
    static let titleSubtitleLeftImage: TableCellDataComponents = [.titleSubtitle, .leftImage]
    static let titleSubtitleDetailsLeftImage: TableCellDataComponents = [.titleSubtitle, .details, .leftImage]
    static let titleSwitchControl: TableCellDataComponents = [.title, .switchControl]
    static let titleDetailsLeftImage: TableCellDataComponents = [.title, .details, .leftImage]
    static let titleSubtitleSwitchControl: TableCellDataComponents = [.titleSwitchControl, .subtitle]
    static let titleSubtitleSwitchControlLeftImage: TableCellDataComponents = [.titleLeftImage, .subtitle, .switchControl]
    static let titleSubtitleDoubleImage: TableCellDataComponents = [.titleSubtitle, .doubleImage]
    static let titleSubtitleDoubleImageImage: TableCellDataComponents = [.titleSubtitle, .doubleImage]
    static let leftImageTitleSubtitleDoubleAction: TableCellDataComponents = [.titleSubtitleLeftImage, .doubleAction]
    static let titleSubtitleDetailsLeftImageBadge: TableCellDataComponents = [.titleSubtitleDetailsLeftImage, .badge]
    static let titleSubtitleLeftImageTopDetails: TableCellDataComponents = [.titleSubtitleLeftImage, .topDetails]
}

public final class TableCellData {
    var tag: Int?

    var title: String?
    var subtitle: String?
    var leftImage: UIImage?
    var leftImagePath: String?
    var details: String?
    var switchState: Bool?
    var doubleImage: (firstImage: UIImage, secondImage: UIImage)?
    var doubleActionImages: (firstImage: UIImage, secondImage: UIImage)?
    var badgeText: String?
    var topDetails: String?

    var isPlaceholder = false

    private(set) var components: TableCellDataComponents = []

    init(title: String? = nil, isPlaceholder: Bool = false, subtitle: String? = nil, leftImage: UIImage? = nil, leftImagePath: String? = nil, details: String? = nil, topDetails: String? = nil, switchState: Bool? = nil, doubleImage: (firstImage: UIImage, secondImage: UIImage)? = nil, doubleActionImages: (firstImage: UIImage, secondImage: UIImage)? = nil, badgeText: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.leftImage = leftImage
        self.leftImagePath = leftImagePath
        self.details = details
        self.topDetails = topDetails
        self.switchState = switchState
        self.isPlaceholder = isPlaceholder
        self.doubleImage = doubleImage
        self.doubleActionImages = doubleActionImages
        self.badgeText = badgeText

        setupComponents()
    }

    private func setupComponents() {
        if title != nil {
            components.insert(.title)
        }

        if subtitle != nil {
            components.insert(.subtitle)
        }

        if leftImage != nil || leftImagePath != nil {
            components.insert(.leftImage)
        }

        if details != nil {
            components.insert(.details)
        }

        if topDetails != nil {
            components.insert(.topDetails)
        }

        if switchState != nil {
            components.insert(.switchControl)
        }

        if doubleImage != nil {
            components.insert(.doubleImage)
        }

        if doubleActionImages != nil {
            components.insert(.doubleAction)
        }

        if badgeText != nil {
            components.insert(.badge)
        }
    }
}
