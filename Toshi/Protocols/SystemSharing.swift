//
//  SystemSharing.swift
//  Debug
//
//  Created by Ellen Shapiro (Work) on 2/9/18.
//  Copyright © 2018 Bakken&Baeck. All rights reserved.
//

import UIKit

protocol SystemSharing {

    /// Shares a single item with the system share sheet
    ///
    /// - Parameter item: The item to share.
    func shareWithSystemSheet(item: Any)

    /// Shares an array of items with the system share sheet.
    ///
    /// - Parameter items: The items to share
    func shareWithSystemSheet(items: [Any])
}

// MARK: - Default Implementation

extension SystemSharing {

    func shareWithSystemSheet(items: [Any]) {
        let shareSheet = UIActivityViewController(activityItems: items, applicationActivities: [])

        Navigator.presentModally(shareSheet)
    }

    func shareWithSystemSheet(item: Any) {
        shareWithSystemSheet(items: [item])
    }
}
