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

final class RecentViewModel {
    
    static let acceptedThreadsFilteringKey = "Accepted_threads_filtering_key"
    static let unacceptedThreadsFilteringKey = "Unaccepted_threads_filtering_key"

    private(set) lazy var acceptedThreadsMappings: YapDatabaseViewMappings = {
        let mappings = YapDatabaseViewMappings(groups: [TSInboxGroup], view: RecentViewModel.acceptedThreadsFilteringKey)
        mappings.setIsReversed(true, forGroup: TSInboxGroup)

        return mappings
    }()

    private(set) lazy var unacceptedThreadsMappings: YapDatabaseViewMappings = {
        let mappings = YapDatabaseViewMappings(groups: [TSInboxGroup], view: RecentViewModel.unacceptedThreadsFilteringKey)
        mappings.setIsReversed(true, forGroup: TSInboxGroup)

        return mappings
    }()

    private(set) lazy var allThreadsMappings: YapDatabaseViewMappings = {
        let mappings = YapDatabaseViewMappings(groups: [TSInboxGroup], view: TSThreadDatabaseViewExtensionName)
        mappings.setIsReversed(true, forGroup: TSInboxGroup)

        return mappings
    }()

    private(set) lazy var uiDatabaseConnection: YapDatabaseConnection = {
        let database = TSStorageManager.shared().database()!
        let dbConnection = database.newConnection()
        dbConnection.beginLongLivedReadTransaction()

        return dbConnection
    }()

    private lazy var filteredDatabaseConnection: YapDatabaseConnection = {
        let database = TSStorageManager.shared().database()!
        let dbConnection = database.newConnection()

        return dbConnection
    }()

    private lazy var filteredView = YapDatabaseFilteredView(parentViewName: TSThreadDatabaseViewExtensionName, filtering: filtering)
    private lazy var unacceptedFilteredView = YapDatabaseFilteredView(parentViewName: TSThreadDatabaseViewExtensionName, filtering: unacceptedThreadsFiltering)

    private var filtering: YapDatabaseViewFiltering {

        let filteringBlock: YapDatabaseViewFilteringWithObjectBlock = { transaction, group, collection, key, object in
            guard let thread = object as? TSThread else { return true }
            return thread.isPendingAccept == false
        }

        return YapDatabaseViewFiltering.withObjectBlock(filteringBlock)
    }

    private var unacceptedThreadsFiltering: YapDatabaseViewFiltering {

        let filteringBlock: YapDatabaseViewFilteringWithObjectBlock = { transaction, group, collection, key, object in
            guard let thread = object as? TSThread else { return true }
            return thread.isPendingAccept == true
        }

        return YapDatabaseViewFiltering.withObjectBlock(filteringBlock)
    }

    private func threadsSorting() -> YapDatabaseViewSorting {
        let viewSorting = YapDatabaseViewSorting.withObjectBlock { (_, _, _, _, _, _, _, _) -> ComparisonResult in
            return .orderedSame
        }

        return viewSorting
    }

    private func setupFiltering() {
        filteredDatabaseConnection.readWrite { [weak self] transaction in
            guard let strongSelf = self else { return }
            guard let acceptedThreadsTransaction = transaction.ext(RecentViewModel.acceptedThreadsFilteringKey) as? YapDatabaseFilteredViewTransaction else { return }

            let tag = Date().timeIntervalSinceReferenceDate
            acceptedThreadsTransaction.setFiltering(strongSelf.filtering, versionTag: String(describing: tag))
            guard let unacceptedThreadsTransaction = transaction.ext(RecentViewModel.unacceptedThreadsFilteringKey) as? YapDatabaseFilteredViewTransaction else { return }

            unacceptedThreadsTransaction.setFiltering(strongSelf.unacceptedThreadsFiltering, versionTag: String(describing: tag))
        }
    }

    @discardableResult
    private func registerDatabaseView() -> Bool {
        guard let database = TSStorageManager.shared().database() else { fatalError("couldn't instantiate the database") }
        // Check if it's already registered.

        let viewGrouping = YapDatabaseViewGrouping.withObjectBlock { (_, _, _, object) -> String? in
            if (object as? Data) != nil {
                return TSThreadDatabaseViewExtensionName
            }

            return nil
        }

        let viewSorting = threadsSorting()

        let options = YapDatabaseViewOptions()
        options.allowedCollections = YapWhitelistBlacklist(whitelist: Set([TSThreadDatabaseViewExtensionName]))

        let databaseView = YapDatabaseAutoView(grouping: viewGrouping, sorting: viewSorting, versionTag: "1", options: options)

        var mainViewIsRegistered = database.registeredExtension(TSThreadDatabaseViewExtensionName) != nil
        if !mainViewIsRegistered {
            mainViewIsRegistered = database.register(databaseView, withName: TSThreadDatabaseViewExtensionName)
        }

        let filteredViewIsRegistered = database.register(filteredView, withName: RecentViewModel.acceptedThreadsFilteringKey)
        let unacceptedThreadsViewIsRegistered = database.register(unacceptedFilteredView, withName: RecentViewModel.unacceptedThreadsFilteringKey)

        return mainViewIsRegistered && filteredViewIsRegistered && unacceptedThreadsViewIsRegistered
    }

    func setupForCurrentSession() {
        registerDatabaseView()
        setupFiltering()
    }
}
