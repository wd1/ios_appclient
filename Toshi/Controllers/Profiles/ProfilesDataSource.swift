import Foundation
import UIKit
import TinyConstraints

protocol ProfilesDatasourceChangesOutput: class {
    func datasourceDidChange(_ datasource: ProfilesDataSource, yapDatabaseChanges: [YapDatabaseViewRowChange])
}

class ProfilesDataSource: NSObject {

    static let filteredProfilesKey = "Filtered_Profiles_Key"
    static let customFilteredProfilesKey = "Custom_Filtered_Profiles_Key"
    
    let type: ProfilesViewControllerType
    private(set) var selectedProfiles = Set<TokenUser>()
    private var allProfiles: [TokenUser] = []

    var changesOutput: ProfilesDatasourceChangesOutput?

    var selectedProfilesIds: [String] = [] {
        didSet {
            guard Yap.isUserSessionSetup else { return }

            adjustToSelections()
        }
    }

    var excludedProfilesIds: [String] = [] {
        didSet {
            guard Yap.isUserSessionSetup else { return }

            adjustToExclusions()
        }
    }
    
    var isEmpty: Bool {
        let currentItemCount = mappings.numberOfItems(inSection: 0)
        return (currentItemCount == 0)
    }

    var searchText: String = "" {
        didSet {
            searchDatabaseConnection.readWrite { [weak self] transaction in
                guard let strongSelf = self else { return }
                guard let filterTransaction = transaction.ext(ProfilesDataSource.filteredProfilesKey) as? YapDatabaseFilteredViewTransaction else { return }

                let tag = Date().timeIntervalSinceReferenceDate
                filterTransaction.setFiltering(strongSelf.filtering, versionTag: String(describing: tag))
            }
        }
    }
    
    private(set) lazy var uiDatabaseConnection: YapDatabaseConnection = {
        let database = Yap.sharedInstance.database
        let dbConnection = database!.newConnection()
        dbConnection.beginLongLivedReadTransaction()

        return dbConnection
    }()

    private lazy var searchDatabaseConnection: YapDatabaseConnection = {
        let database = Yap.sharedInstance.database
        let dbConnection = database!.newConnection()

        return dbConnection
    }()

    private lazy var customFilterDatabaseConnection: YapDatabaseConnection = {
        let database = Yap.sharedInstance.database
        let dbConnection = database!.newConnection()

        return dbConnection
    }()

    private var customFiltering: YapDatabaseViewFiltering {

        let filteringBlock: YapDatabaseViewFilteringWithObjectBlock = { [weak self] transaction, group, colelction, key, object in
            guard let strongSelf = self else { return true }
            guard let data = object as? Data, let deserialised = (try? JSONSerialization.jsonObject(with: data, options: [])), var json = deserialised as? [String: Any], let address = json[TokenUser.Constants.address] as? String else { return false }

            return !strongSelf.excludedProfilesIds.contains(address)
        }

        return YapDatabaseViewFiltering.withObjectBlock(filteringBlock)
    }

    private var filtering: YapDatabaseViewFiltering {

        let filteringBlock: YapDatabaseViewFilteringWithObjectBlock = { transaction, group, colelction, key, object in
            guard self.searchText.length > 0 else { return true }
            guard let data = object as? Data, let deserialised = (try? JSONSerialization.jsonObject(with: data, options: [])), var json = deserialised as? [String: Any], let username = json[TokenUser.Constants.username] as? String else { return false }

            return username.lowercased().contains(self.searchText.lowercased())
        }

        return YapDatabaseViewFiltering.withObjectBlock(filteringBlock)
    }

    private lazy var customFilteredView = YapDatabaseFilteredView(parentViewName: TokenUser.viewExtensionName, filtering: customFiltering)
    private lazy var filteredView = YapDatabaseFilteredView(parentViewName: ProfilesDataSource.customFilteredProfilesKey, filtering: filtering)
    
    private(set) lazy var mappings: YapDatabaseViewMappings = {
        let mappings = YapDatabaseViewMappings(groups: [TokenUser.favoritesCollectionKey], view: ProfilesDataSource.filteredProfilesKey)
        mappings.setIsReversed(true, forGroup: TokenUser.favoritesCollectionKey)
        
        return mappings
    }()

    // MARK: - Initialization

    init(type: ProfilesViewControllerType) {
        self.type = type

        super.init()

        if Yap.isUserSessionSetup {
            prepareDatabaseViews()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userCreated(_:)), name: .userCreated, object: nil)
    }

    // MARK: - Notification setup

    @objc private func userCreated(_ notification: Notification) {
        DispatchQueue.main.async {
            guard Yap.isUserSessionSetup else { return }

            self.prepareDatabaseViews()
            self.adjustToSelections()
            self.adjustToExclusions()
        }
    }

    // MARK: - Private API

    private func adjustToSelections() {
        let selectedIdsSet = Set<String>(selectedProfilesIds)

        for profileId in selectedIdsSet {
            guard let selectedProfile = allProfiles.first(where: { $0.address == profileId }) else { continue }
            selectedProfiles.insert(selectedProfile)
        }
    }

    private func adjustToExclusions() {
        customFilterDatabaseConnection.readWrite { [weak self] transaction in
            guard let strongSelf = self else { return }
            guard let filterTransaction = transaction.ext(ProfilesDataSource.customFilteredProfilesKey) as? YapDatabaseFilteredViewTransaction else { return }

            let tag = Date().timeIntervalSinceReferenceDate
            filterTransaction.setFiltering(strongSelf.customFiltering, versionTag: String(describing: tag))
        }
    }

    @discardableResult
    private func registerTokenContactsDatabaseView() -> Bool {
        guard let database = Yap.sharedInstance.database else { fatalError("couldn't instantiate the database") }
        // Check if it's already registered.

        let viewGrouping = YapDatabaseViewGrouping.withObjectBlock { (_, _, _, object) -> String? in
            if (object as? Data) != nil {
                return TokenUser.favoritesCollectionKey
            }

            return nil
        }

        let viewSorting = contactSorting()

        let options = YapDatabaseViewOptions()
        options.allowedCollections = YapWhitelistBlacklist(whitelist: Set([TokenUser.favoritesCollectionKey]))

        let databaseView = YapDatabaseAutoView(grouping: viewGrouping, sorting: viewSorting, versionTag: "1", options: options)

        var mainViewIsRegistered = database.registeredExtension(TokenUser.viewExtensionName) != nil
        if !mainViewIsRegistered {
            mainViewIsRegistered = database.register(databaseView, withName: TokenUser.viewExtensionName)
        }

        var customFilteredViewIsRegistered = database.registeredExtension(ProfilesDataSource.customFilteredProfilesKey) != nil
        if !customFilteredViewIsRegistered {
            customFilteredViewIsRegistered = database.register(customFilteredView, withName: ProfilesDataSource.customFilteredProfilesKey)
        }

        let filteredViewIsRegistered = database.register(filteredView, withName: ProfilesDataSource.filteredProfilesKey)

        return mainViewIsRegistered && customFilteredViewIsRegistered && filteredViewIsRegistered
    }

    private func contactSorting() -> YapDatabaseViewSorting {
        let viewSorting = YapDatabaseViewSorting.withObjectBlock { (_, _, _, _, object1, _, _, object2) -> ComparisonResult in
            if let data1 = object1 as? Data, let data2 = object2 as? Data,
                let contact1 = TokenUser.user(with: data1),
                let contact2 = TokenUser.user(with: data2) {

                return contact1.username.compare(contact2.username)
            }

            return .orderedAscending
        }

        return viewSorting
    }

    private func setupAllProfilesCollection() {
        let profilesCount = Int(mappings.numberOfItems(inSection: UInt(0)))

        for profileIndex in 0 ..< profilesCount {
            guard let profile = profile(at: IndexPath(row: profileIndex, section: 0)) else { return }

            allProfiles.append(profile)
        }
    }
    
    // MARK: - Public API

    func numberOfSections() -> Int {
        return Int(mappings.numberOfSections())
    }

    func numberOfItems(in section: Int) -> Int {
        return Int(mappings.numberOfItems(inSection: UInt(section)))
    }

    func profile(at indexPath: IndexPath) -> TokenUser? {
        var profile: TokenUser?
        
        uiDatabaseConnection.read { [weak self] transaction in
            guard let strongSelf = self,
                let dbExtension: YapDatabaseViewTransaction = transaction.extension(ProfilesDataSource.filteredProfilesKey) as? YapDatabaseViewTransaction,
                let data = dbExtension.object(at: indexPath, with: strongSelf.mappings) as? Data else { return }
            
            profile = TokenUser.user(with: data, shouldUpdate: false)
        }
        
        return profile
    }

    func isProfileSelected(_ profile: TokenUser) -> Bool {
        return selectedProfiles.contains(profile)
    }

    func updateSelection(at indexPath: IndexPath) {
        guard let profile = profile(at: indexPath) else { return }

        if selectedProfiles.contains(profile) {
            selectedProfiles.remove(profile)
        } else {
            selectedProfiles.insert(profile)
        }
    }

    func rightBarButtonEnabled() -> Bool {
        switch type {
        case .newChat, .updateGroupChat, .favorites:
            return true
        default:
            return selectedProfiles.count > 1
        }
    }

    func prepareDatabaseViews() {
        registerTokenContactsDatabaseView()

        uiDatabaseConnection.read { [weak self] transaction in
            self?.mappings.update(with: transaction)
        }

        setupAllProfilesCollection()
    }
    
    // MARK: - Database handling
    
    @objc private func yapDatabaseDidChange(notification _: NSNotification) {
        let notifications = uiDatabaseConnection.beginLongLivedReadTransaction()
        
        // swiftlint:disable:next force_cast
        let threadViewConnection = uiDatabaseConnection.ext(ProfilesDataSource.filteredProfilesKey) as! YapDatabaseViewConnection
        
        if !threadViewConnection.hasChanges(for: notifications) {
            uiDatabaseConnection.read { [weak self] transaction in
                self?.mappings.update(with: transaction)
            }
            
            return
        }
        
        let yapDatabaseChanges = threadViewConnection.getChangesFor(notifications: notifications, with: mappings)
        let isDatabaseChanged = yapDatabaseChanges.rowChanges.count != 0 || yapDatabaseChanges.sectionChanges.count != 0
        
        guard isDatabaseChanged else { return }
        
        self.changesOutput?.datasourceDidChange(self, yapDatabaseChanges: yapDatabaseChanges.rowChanges)
    }
}
