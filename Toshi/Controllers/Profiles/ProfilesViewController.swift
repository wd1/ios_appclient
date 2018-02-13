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

// MARK: - Profiles View Controller Type

public enum ProfilesViewControllerType {
    case favorites
    case newChat
    case newGroupChat
    case updateGroupChat
    
    var title: String {
        switch self {
        case .favorites:
            return Localized("profiles_navigation_title_favorites")
        case .newChat:
            return Localized("profiles_navigation_title_new_chat")
        case .newGroupChat:
            return Localized("profiles_navigation_title_new_group_chat")
        case .updateGroupChat:
            return Localized("profiles_navigation_title_update_group_chat")
        }
    }
}

protocol ProfilesListCompletionOutput: class {
    func didFinish(_ controller: ProfilesViewController, selectedProfilesIds: [String])
}

// MARK: - Profiles View Controller

final class ProfilesViewController: UITableViewController, Emptiable {
    
    let type: ProfilesViewControllerType

    var scrollViewBottomInset: CGFloat = 0
    private(set) weak var output: ProfilesListCompletionOutput?

    let emptyView = EmptyView(title: Localized("favorites_empty_title"), description: Localized("favorites_empty_description"), buttonTitle: Localized("invite_friends_action_title"))
    
    var scrollView: UIScrollView {
        return tableView
    }

    // MARK: - Lazy Vars
    
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel(_:)))
    private lazy var doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapDone(_:)))
    private lazy var addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd(_:)))

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.dimsBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        controller.searchBar.delegate = self
        controller.searchBar.barTintColor = Theme.viewBackgroundColor
        controller.searchBar.tintColor = Theme.tintColor
        controller.searchBar.placeholder = Localized("profiles_search_bar_title")
        
        guard #available(iOS 11.0, *) else {
            controller.searchBar.searchBarStyle = .minimal
            controller.searchBar.backgroundColor = Theme.viewBackgroundColor
            controller.searchBar.layer.borderWidth = .lineHeight
            controller.searchBar.layer.borderColor = Theme.borderColor.cgColor
            
            return controller
        }
        
        let searchField = controller.searchBar.value(forKey: "searchField") as? UITextField
        searchField?.backgroundColor = Theme.inputFieldBackgroundColor
        
        return controller
    }()

    private var isMultipleSelectionMode: Bool {
        return type == .newGroupChat || type == .updateGroupChat
    }
    
    private(set) var dataSource: ProfilesDataSource
    
    // MARK: - Initialization
    
    required public init(datasource: ProfilesDataSource, output: ProfilesListCompletionOutput? = nil) {

        self.dataSource = datasource

        self.type = datasource.type

        super.init(nibName: nil, bundle: nil)

        self.dataSource.changesOutput = self
        
        title = type.title
        self.output = output
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ProfileCell.self)

        setupTableHeader()
        setupNavigationBarButtons()

        definesPresentationContext = true

        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = Theme.viewBackgroundColor
        tableView.separatorStyle = .none

        let appearance = UIButton.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        appearance.setTitleColor(Theme.greyTextColor, for: .normal)
        
        updateHeaderWithSelections()

        displayContacts()
        setupEmptyView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        preferLargeTitleIfPossible(true)

        showOrHideEmptyState()

        dataSource.searchText = ""
        
        if dataSource.type != .updateGroupChat {
            dataSource.excludedProfilesIds = []
        }
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

    public override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch type {
        case .favorites,
             .newChat:
            guard let profile = dataSource.profile(at: indexPath) else { return }
            didSelectProfile(profile: profile)
        case .newGroupChat, .updateGroupChat:
            dataSource.updateSelection(at: indexPath)
            updateHeaderWithSelections()
            reloadData()
            navigationItem.rightBarButtonItem?.isEnabled = dataSource.rightBarButtonEnabled()
        }
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections()
    }

    public override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfItems(in: section)
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ProfileCell.self, for: indexPath)
        
        guard let profile = dataSource.profile(at: indexPath) else {
            assertionFailure("Could not get profile at indexPath: \(indexPath)")
            return cell
        }

        cell.avatarPath = profile.avatarPath
        cell.name = profile.name
        cell.displayUsername = profile.displayUsername

        if isMultipleSelectionMode {
            cell.selectionStyle = .none
            cell.isCheckmarkShowing = true
            cell.isCheckmarkChecked = dataSource.isProfileSelected(profile)
        }

        return cell
    }

    private var isMultipleSelectionSetup: Bool {
        return type == .newGroupChat || type == .updateGroupChat
    }

    private func updateHeaderWithSelections() {
        guard isMultipleSelectionSetup else { return }
        guard
            let header = tableView?.tableHeaderView as? ProfilesHeaderView,
            let selectedProfilesView = header.addedHeader else {
                assertionFailure("Couldn't access header!")
                return
        }

        selectedProfilesView.updateDisplay(with: dataSource.selectedProfiles)
    }

    private func didSelectProfile(profile: TokenUser) {
        searchController.searchBar.resignFirstResponder()

        if type == .newChat {
            output?.didFinish(self, selectedProfilesIds: [profile.address])
        } else {
            navigationController?.pushViewController(ProfileViewController(profile: profile), animated: true)
            UserDefaultsWrapper.selectedContact = profile.address
        }
    }
    
    // MARK: - View Setup

    private func setupTableHeader() {
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            tableView.tableHeaderView = ProfilesHeaderView(type: type, delegate: self)
        } else {
            tableView.tableHeaderView = ProfilesHeaderView(with: searchController.searchBar, type: type, delegate: self)

            if Navigator.topViewController == self {
                tableView.layoutIfNeeded()
            }
        }
    }
    
    private func setupEmptyView() {
        view.addSubview(emptyView)
        emptyView.actionButton.addTarget(self, action: #selector(emptyViewButtonPressed(_:)), for: .touchUpInside)
        emptyView.edges(to: layoutGuide())
    }
    
    private func setupNavigationBarButtons() {
        switch type {
        case .newChat:
            navigationItem.leftBarButtonItem = cancelButton
        case .favorites:
            navigationItem.rightBarButtonItem = addButton
        case .newGroupChat, .updateGroupChat:
            navigationItem.rightBarButtonItem = doneButton
            doneButton.isEnabled = false
        }
    }

    private func displayContacts() {
        reloadData()
        showOrHideEmptyState()
    }
    
    // MARK: - Action Handling
    
    @objc func emptyViewButtonPressed(_ button: ActionButton) {
        shareWithSystemSheet(item: Localized("sharing_action_item"))
    }
    
    private func showOrHideEmptyState() {
        let emptyViewHidden = (searchController.isActive || !dataSource.isEmpty)
        emptyView.isHidden = emptyViewHidden
        tableView.tableHeaderView?.isHidden = !emptyViewHidden
    }
    
    @objc private func didTapCancel(_ button: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc private func didTapAdd(_ button: UIBarButtonItem) {
        let addContactSheet = UIAlertController(title: Localized("favorites_add_title"), message: nil, preferredStyle: .actionSheet)
        
        addContactSheet.addAction(UIAlertAction(title: Localized("favorites_add_by_username"), style: .default, handler: { _ in
            self.searchController.searchBar.becomeFirstResponder()
        }))
        
        addContactSheet.addAction(UIAlertAction(title: Localized("invite_friends_action_title"), style: .default, handler: { _ in

            self.shareWithSystemSheet(item: Localized("sharing_action_item"))
        }))
        
        addContactSheet.addAction(UIAlertAction(title: Localized("favorites_scan_code"), style: .default, handler: { _ in
            Navigator.presentScanner()
        }))

        addContactSheet.addAction(UIAlertAction(title: Localized("cancel_action_title"), style: .cancel, handler: nil))
        
        addContactSheet.view.tintColor = Theme.tintColor
        present(addContactSheet, animated: true)
    }
    
    @objc private func didTapDone(_ button: UIBarButtonItem) {
        guard dataSource.selectedProfiles.count > 0 else {
            assertionFailure("No selected profiles?!")

            return
        }

        let membersIdsArray = dataSource.selectedProfiles.sorted { $0.username < $1.username }.map { $0.address }

        if type == .updateGroupChat {
            navigationController?.popViewController(animated: true)
            output?.didFinish(self, selectedProfilesIds: membersIdsArray)
        } else if type == .newGroupChat {
            guard let groupModel = TSGroupModel(title: "", memberIds: NSMutableArray(array: membersIdsArray), image: UIImage(named: "avatar-edit-placeholder"), groupId: nil) else { return }

            let viewModel = NewGroupViewModel(groupModel)
            let groupViewController = GroupViewController(viewModel, configurator: NewGroupConfigurator())
            navigationController?.pushViewController(groupViewController, animated: true)
        }
    }

    // MARK: - Table View Reloading

    func reloadData() {
        if #available(iOS 11.0, *) {
            // Must perform batch updates on iOS 11 or you'll get super-wonky layout because of the headers.
            tableView?.performBatchUpdates({
                self.tableView?.reloadData()
            }, completion: nil)
        } else {
            tableView?.reloadData()
        }
    }
}

// MARK: - Mix-in extensions

extension ProfilesViewController: SystemSharing { /* mix-in */ }

// MARK: - Search Bar Delegate

extension ProfilesViewController: UISearchBarDelegate {
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        
        if type != .newChat {
            displayContacts()
        }
    }
}

// MARK: - Search Results Updating

extension ProfilesViewController: UISearchResultsUpdating {
    
    public func updateSearchResults(for searchController: UISearchController) {

        dataSource.searchText = searchController.searchBar.text ?? ""
    }
}

// MARK: - Profiles Add Group Header Delegate

extension ProfilesViewController: ProfilesAddGroupHeaderDelegate {
    
    func newGroup() {
        let datasource = ProfilesDataSource(type: .newGroupChat)
        let groupChatSelection = ProfilesViewController(datasource: datasource)
        navigationController?.pushViewController(groupChatSelection, animated: true)
    }
}

extension ProfilesViewController: ProfilesDatasourceChangesOutput {

    func datasourceDidChange(_ datasource: ProfilesDataSource, yapDatabaseChanges: [YapDatabaseViewRowChange]) {

        if navigationController?.topViewController == self && tabBarController?.selectedViewController == navigationController {
            tableView?.beginUpdates()

            for rowChange in yapDatabaseChanges {

                switch rowChange.type {
                case .delete:
                    guard let indexPath = rowChange.indexPath else { continue }
                    tableView?.deleteRows(at: [indexPath], with: .none)
                case .insert:
                    guard let newIndexPath = rowChange.newIndexPath else { continue }
                    tableView?.insertRows(at: [newIndexPath], with: .none)
                case .move:
                    guard let newIndexPath = rowChange.newIndexPath, let indexPath = rowChange.indexPath else { continue }
                    tableView?.deleteRows(at: [indexPath], with: .none)
                    tableView?.insertRows(at: [newIndexPath], with: .none)
                case .update:
                    guard let indexPath = rowChange.indexPath else { continue }
                    tableView?.reloadRows(at: [indexPath], with: .none)
                }
            }

            tableView?.endUpdates()
        } else {
            tableView.reloadData()
        }

        showOrHideEmptyState()
    }
}
