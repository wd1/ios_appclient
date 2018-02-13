// Copyright (c) 2017 Token Browser, Inc
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
import SweetFoundation
import SweetSwift
import TinyConstraints

class FavoritesController: SweetTableController, KeyboardAdjustable, Emptiable {
    
    let emptyView = EmptyView(title: Localized("favorites_empty_title"), description: Localized("favorites_empty_description"), buttonTitle: Localized("invite_friends_action_title"))
    
    var scrollViewBottomInset: CGFloat = 0.0

    let filteredDatabaseViewName = "filteredDatabaseViewName"

    var scrollView: UIScrollView {
        return tableView
    }

    var keyboardWillShowSelector: Selector {
        return #selector(keyboardShownNotificationReceived(_:))
    }

    var keyboardWillHideSelector: Selector {
        return #selector(keyboardHiddenNotificationReceived(_:))
    }

    private lazy var filteredView: YapDatabaseFilteredView = {
        return YapDatabaseFilteredView(parentViewName: TokenUser.viewExtensionName, filtering: filtering)
    }()

    private var filtering: YapDatabaseViewFiltering {

        let searchText = searchController.searchBar.text?.lowercased() ?? ""

        let filteringBlock: YapDatabaseViewFilteringWithObjectBlock = { transaction, group, colelction, key, object in

            guard searchText.length > 0 else { return true }

            if let data = object as? Data, let deserialised = (try? JSONSerialization.jsonObject(with: data, options: [])),
                var json = deserialised as? [String: Any], let username = json[TokenUser.Constants.username] as? String {

                return username.lowercased().contains(searchText)
            }

            return false
        }

        return YapDatabaseViewFiltering.withObjectBlock(filteringBlock)
    }

    @objc private func keyboardShownNotificationReceived(_ notification: NSNotification) {
        keyboardWillShow(notification)
    }

    @objc private func keyboardHiddenNotificationReceived(_ notification: NSNotification) {
        keyboardWillHide(notification)
    }

    private lazy var mappings: YapDatabaseViewMappings = {
        let mappings = YapDatabaseViewMappings(groups: [TokenUser.favoritesCollectionKey], view: filteredDatabaseViewName)
        mappings.setIsReversed(true, forGroup: TokenUser.favoritesCollectionKey)

        return mappings
    }()

    private lazy var uiDatabaseConnection: YapDatabaseConnection = {
        let database = Yap.sharedInstance.database
        let dbConnection = database!.newConnection()
        dbConnection.beginLongLivedReadTransaction()

        return dbConnection
    }()

    private lazy var databaseConnection: YapDatabaseConnection = {
        let database = Yap.sharedInstance.database
        let dbConnection = database!.newConnection()

        return dbConnection
    }()

    private var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.didPressCancel(_:)))
    private lazy var addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAddButton))

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self

        controller.dimsBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        
        controller.searchBar.delegate = self
        controller.searchBar.barTintColor = Theme.viewBackgroundColor
        controller.searchBar.tintColor = Theme.tintColor

        controller.searchBar.placeholder = "Search by username"

        guard #available(iOS 11.0, *) else {
            controller.searchBar.searchBarStyle = .minimal
            controller.searchBar.backgroundColor = Theme.viewBackgroundColor
            controller.searchBar.layer.borderWidth = 1.0 / UIScreen.main.scale
            controller.searchBar.layer.borderColor = Theme.borderColor.cgColor

            return controller
        }

        let searchField = controller.searchBar.value(forKey: "searchField") as? UITextField
        searchField?.backgroundColor = Theme.inputFieldBackgroundColor

        return controller
    }()
    
    private var isPresentedModally: Bool {
        return navigationController?.presentingViewController != nil
    }
    
    init() {
        super.init(style: .plain)

        if TokenUser.current != nil {
            setupForCurrentUserNotifications()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(userCreated(_:)), name: .userCreated, object: nil)
    }

    @objc private func userCreated(_ notification: Notification) {
        DispatchQueue.main.async {
            self.setupForCurrentUserNotifications()
        }
    }

    private func setupForCurrentUserNotifications() {
        registerTokenContactsDatabaseView()

        uiDatabaseConnection.asyncRead { [weak self] transaction in
            self?.mappings.update(with: transaction)
        }

        registerDatabaseNotifications()
    }

    required init?(coder _: NSCoder) {
        fatalError("")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForKeyboardNotifications()

        tableView.register(ContactCell.self)
        tableView.estimatedRowHeight = 80

        tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = Theme.viewBackgroundColor
        tableView.separatorStyle = .none

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
        if isPresentedModally {
            navigationItem.leftBarButtonItem = cancelButton
        } else {
            navigationItem.rightBarButtonItem = addButton
        }
        
        definesPresentationContext = true

        let appearance = UIButton.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        appearance.setTitleColor(Theme.greyTextColor, for: .normal)

        displayContacts()

        if let address = UserDefaultsWrapper.selectedContact, !isPresentedModally {
            // This doesn't restore a contact if they are not our contact, but a search result
            DispatchQueue.main.asyncAfter(seconds: 0.0) {
                guard let contact = self.contact(with: address) else { return }

                let appController = ProfileViewController(contact: contact)
                self.navigationController?.pushViewController(appController, animated: false)
            }
        }
        
        addSubviewsAndConstraints()
    }
    
    @objc func emptyViewButtonPressed(_ button: ActionButton) {
        let shareController = UIActivityViewController(activityItems: ["Get Toshi, available for iOS and Android! (https://www.toshi.org)"], applicationActivities: [])
        Navigator.presentModally(shareController)
    }
    
    @objc private func didPressCancel(_ barButtonItem: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        title = isPresentedModally ? Localized("favorites_navigation_title_new_chat") : Localized("favorites_navigation_title")

        preferLargeTitleIfPossible(true)

        tableView.reloadData()
        showOrHideEmptyState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        scrollViewBottomInset = tableView.contentInset.bottom
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        for view in searchController.searchBar.subviews {
            view.clipsToBounds = false
        }
        searchController.searchBar.superview?.clipsToBounds = false
    }

    private func addSubviewsAndConstraints() {
        let tableHeaderHeight = tableView.tableHeaderView?.frame.height ?? 0

        tableView.edges(to: view)
        
        view.addSubview(emptyView)
        emptyView.actionButton.addTarget(self, action: #selector(emptyViewButtonPressed(_:)), for: .touchUpInside)
        emptyView.edges(to: layoutGuide(), insets: UIEdgeInsets(top: tableHeaderHeight, left: 0, bottom: 0, right: 0))
    }

    private func showOrHideEmptyState() {
        emptyView.isHidden = searchController.isActive || mappings.numberOfItems(inSection: 0) > 0
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

    @discardableResult
    private func registerTokenContactsDatabaseView() -> Bool {
        guard let database = Yap.sharedInstance.database else { fatalError("couldn't instantiate the database") }
        // Check if it's already registered.
        guard database.registeredExtension(TokenUser.viewExtensionName) == nil else { return true }

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

        let mainViewIsRegistered: Bool = database.register(databaseView, withName: TokenUser.viewExtensionName)
        let filteredViewIsRegistered = database.register(filteredView, withName: filteredDatabaseViewName)

        return mainViewIsRegistered && filteredViewIsRegistered
    }

    private func displayContacts() {
        tableView.reloadData()
        showOrHideEmptyState()
    }

    private func registerDatabaseNotifications() {
        let notificationController = NotificationCenter.default
        notificationController.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
    }

    @objc
    private func yapDatabaseDidChange(notification _: NSNotification) {
        defer {
           showOrHideEmptyState()
        }

        let notifications = uiDatabaseConnection.beginLongLivedReadTransaction()

        // If changes do not affect current view, update and return without updating collection view
        // swiftlint:disable force_cast
        let threadViewConnection = uiDatabaseConnection.ext(filteredDatabaseViewName) as! YapDatabaseViewConnection
        // swiftlint:enable force_cast
        let hasChangesForCurrentView = threadViewConnection.hasChanges(for: notifications)
        if !hasChangesForCurrentView {
            uiDatabaseConnection.read { [weak self] transaction in
                self?.mappings.update(with: transaction)
            }

            return
        }

        let yapDatabaseChanges = threadViewConnection.getChangesFor(notifications: notifications, with: mappings)
        let isDatabaseChanged = yapDatabaseChanges.rowChanges.count != 0 || yapDatabaseChanges.sectionChanges.count != 0

        guard isDatabaseChanged else { return }

        tableView.beginUpdates()

        for rowChange in yapDatabaseChanges.rowChanges {

            switch rowChange.type {
            case .delete:
                guard let indexPath = rowChange.indexPath else { continue }

                tableView.deleteRows(at: [indexPath], with: .none)
            case .insert:
                guard let newIndexPath = rowChange.newIndexPath else { continue }

                updateContactIfNeeded(at: newIndexPath)
                tableView.insertRows(at: [newIndexPath], with: .none)
            case .move:
                guard let newIndexPath = rowChange.newIndexPath, let indexPath = rowChange.indexPath else { continue }

                tableView.deleteRows(at: [indexPath], with: .none)
                tableView.insertRows(at: [newIndexPath], with: .none)
            case .update:
                guard let indexPath = rowChange.indexPath else { continue }

                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }

        tableView.endUpdates()
    }

    private func updateContactIfNeeded(at indexPath: IndexPath) {
        guard let contact = contact(at: indexPath) else { return }

        DLog("Updating contact info for address: \(contact.address).")

        idAPIClient.findContact(name: contact.address) { [weak self] contact in
            if let contact = contact {
                DLog("Added contact info for \(contact.username)")

                self?.tableView.beginUpdates()
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                self?.tableView.endUpdates()
            }
        }
    }

    private func contact(at indexPath: IndexPath) -> TokenUser? {
        var contact: TokenUser?

        uiDatabaseConnection.read { [weak self] transaction in
            guard let strongSelf = self else { return }
            guard let dbExtension: YapDatabaseViewTransaction = transaction.extension(strongSelf.filteredDatabaseViewName) as? YapDatabaseViewTransaction else { return }

            guard let data = dbExtension.object(at: indexPath, with: strongSelf.mappings) as? Data else { return }

            contact = TokenUser.user(with: data, shouldUpdate: false)
        }

        return contact
    }

    private func contact(with address: String) -> TokenUser? {
        var contact: TokenUser?

        uiDatabaseConnection.read { transaction in
            if let data = transaction.object(forKey: address, inCollection: TokenUser.favoritesCollectionKey) as? Data {
                contact = TokenUser.user(with: data)
            }
        }

        return contact
    }

    @objc
    private func didTapAddButton() {
        let addContactSheet = UIAlertController(title: Localized("favorites_add_title"), message: nil, preferredStyle: .actionSheet)

        addContactSheet.addAction(UIAlertAction(title: Localized("favorites_add_by_username"), style: .default, handler: { _ in
            self.searchController.searchBar.becomeFirstResponder()
        }))

        addContactSheet.addAction(UIAlertAction(title: Localized("invite_friends_action_title"), style: .default, handler: { _ in
            let shareController = UIActivityViewController(activityItems: ["Get Toshi, available for iOS and Android! (https://www.toshi.org)"], applicationActivities: [])

            Navigator.presentModally(shareController)
        }))

        addContactSheet.addAction(UIAlertAction(title: Localized("favorites_scan_code"), style: .default, handler: { _ in
            guard let tabBarController = self.tabBarController as? TabBarController else { return }
            tabBarController.switch(to: .scanner)
        }))

        addContactSheet.addAction(UIAlertAction(title: Localized("cancel_action_title"), style: .cancel, handler: nil))

        addContactSheet.view.tintColor = Theme.tintColor
        present(addContactSheet, animated: true) {
            // Due to a UIKit "bug", tint colour need be reset here.
            addContactSheet.view.tintColor = Theme.tintColor
        }
    }
}

extension FavoritesController: UITableViewDataSource {

    func numberOfSections(in _: UITableView) -> Int {
        return Int(mappings.numberOfSections())
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(mappings.numberOfItems(inSection: UInt(section)))
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ContactCell.self, for: indexPath)
        cell.contact = contact(at: indexPath)

        return cell
    }
}

extension FavoritesController: UITableViewDelegate {

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        searchController.searchBar.resignFirstResponder()
        
        if let contact = contact(at: indexPath) {
            
            if isPresentedModally {
                ChatInteractor.getOrCreateThread(for: contact.address)
                
                DispatchQueue.main.async {
                    Navigator.tabbarController?.displayMessage(forAddress: contact.address)
                    self.dismiss(animated: true)
                }
            } else {
                let contactController = ProfileViewController(contact: contact)
                self.navigationController?.pushViewController(contactController, animated: true)
                            
                UserDefaultsWrapper.selectedContact = contact.address
            }
        }
    }
}

extension FavoritesController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        
        if !isPresentedModally {
            displayContacts()
        }
    }
}

extension FavoritesController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {

        databaseConnection.readWrite { [weak self] transaction in
            guard let strongSelf = self else { return }
            guard let filterTransaction = transaction.ext(strongSelf.filteredDatabaseViewName) as? YapDatabaseFilteredViewTransaction else { return }

            let tag = Date().timeIntervalSinceReferenceDate
            filterTransaction.setFiltering(strongSelf.filtering, versionTag: String(describing: tag))
        }
    }
}
