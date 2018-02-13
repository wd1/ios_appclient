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

import SweetFoundation
import UIKit
import SweetUIKit

enum BrowseContentSection: Int {
    case topRatedApps
    case featuredDapps
    case topRatedPublicUsers
    case latestPublicUsers
    
    var title: String {
        switch self {
        case .topRatedApps:
            return Localized("browse-top-rated-apps")
        case .featuredDapps:
            return Localized("browse-featured-dapps")
        case .topRatedPublicUsers:
            return Localized("browse-top-rated-public-users")
        case .latestPublicUsers:
            return Localized("browse-latest-public-users")
        }
    }
}

protocol BrowseableItem {
    
    var nameForBrowseAndSearch: String { get }
    var descriptionForSearch: String { get }
    var avatarPath: String { get }
    var shouldShowRating: Bool { get }
    var rating: Float? { get }
}

class BrowseViewController: SearchableCollectionController {
    private var cacheQueue = DispatchQueue(label: "org.toshi.cacheQueue")
    private var contentSections: [BrowseContentSection] = [.topRatedApps, .featuredDapps, .topRatedPublicUsers, .latestPublicUsers]
    private var items: [[BrowseableItem]] = [[], [], [], []]
    private var openURLButtonTopAnchor: NSLayoutConstraint?
    
    private lazy var searchResultView: BrowseSearchResultView = {
        let view = BrowseSearchResultView()
        view.searchDelegate = self
        view.isHidden = true
        
        return view
    }()
    
    private lazy var openURLButton: OpenURLButton = {
        let view = OpenURLButton(withAutoLayout: true)
        view.isHidden = true
        view.addTarget(self, action: #selector(didTapOpenURL(_:)), for: .touchUpInside)
        
        return view
    }()
    
    private lazy var openButtonAttributes: [NSAttributedStringKey: Any] = {
        return [.foregroundColor: Theme.tintColor, .font: Theme.regular(size: 14)]
    }()
    
    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        return layout
    }()
    
    var topInset: CGFloat {
        return (navigationController?.navigationBar.bounds.height ?? 0) + searchController.searchBar.frame.height + UIApplication.shared.statusBarFrame.height
    }
    
    var bottomInset: CGFloat {
        return tabBarController?.tabBar.bounds.height ?? 0
    }
    
    init() {
        super.init()
        
        collectionView.register(BrowseCollectionViewCell.self)
        automaticallyAdjustsScrollViewInsets = false
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Localized("browse-navigation-title")
        
        collectionView.showsVerticalScrollIndicator = true
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = Theme.viewBackgroundColor
        collectionView.dataSource = self
        collectionView.setCollectionViewLayout(layout, animated: false)
        collectionView.delegate = self
        
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        
        collectionView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
        
        searchBar.delegate = self
        searchBar.barTintColor = Theme.viewBackgroundColor
        searchBar.tintColor = Theme.tintColor
        searchBar.placeholder = Localized("browse-search-placeholder")
        
        let searchField = searchBar.value(forKey: "searchField") as? UITextField
        searchField?.backgroundColor = Theme.inputFieldBackgroundColor
        
        addSubviewsAndConstraints()
    }
    
    private func addSubviewsAndConstraints() {
        view.addSubview(searchResultView)
        view.addSubview(openURLButton)
        
        searchResultView.top(to: view, offset: 64)
        searchResultView.left(to: view)
        searchResultView.bottom(to: view)
        searchResultView.right(to: view)
        
        openURLButton.height(44)
        openURLButton.left(to: view).isActive = true
        openURLButton.right(to: view).isActive = true
        openURLButtonTopAnchor = openURLButton.top(to: collectionView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: animated)

        preferLargeTitleIfPossible(true)
        loadItems()
        
        collectionView.collectionViewLayout.invalidateLayout()
        
        if let indexPathForSelectedRow = searchResultView.indexPathForSelectedRow {
            searchResultView.deselectRow(at: indexPathForSelectedRow, animated: true)
        }
        
        searchBar.text = nil
        hideOpenURLButtonIfNeeded(animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        searchBar.resignFirstResponder()
        clearSearch()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        collectionView.scrollIndicatorInsets.top = max(0, scrollView.contentOffset.y * -1)
        collectionView.scrollIndicatorInsets.bottom = bottomInset
    }
    
    func dismissSearch() {
        searchController.dismiss(animated: false, completion: nil)
    }
    
    private func showResults(_ apps: [BrowseableItem]?, in section: BrowseContentSection, _ error: Error? = nil) {
        if let error = error {
            let alertController = UIAlertController.errorAlert(error as NSError)
            Navigator.presentModally(alertController)
        }
        
        items[section.rawValue] = apps ?? []
        collectionView.collectionViewLayout.invalidateLayout()
        
        collectionView.performBatchUpdates({
            self.collectionView.reloadItems(at: [IndexPath(item: section.rawValue, section: 0)])
        }, completion: nil)
    }
    
    private func loadItems() {
        AppsAPIClient.shared.getTopRatedApps { [weak self] apps, error in
            self?.showResults(apps, in: .topRatedApps, error)
        }
        
        IDAPIClient.shared.getDapps { [weak self] dapps, error in
            self?.showResults(dapps, in: .featuredDapps, error)
        }
        
        IDAPIClient.shared.getTopRatedPublicUsers { [weak self] users, error in
            self?.showResults(users, in: .topRatedPublicUsers, error)
        }
        
        IDAPIClient.shared.getLatestPublicUsers { [weak self] users, error in
            self?.showResults(users, in: .latestPublicUsers, error)
        }
    }
    
    private func avatar(for indexPath: IndexPath, in section: Int, completion: @escaping ((UIImage?) -> Void)) {
        guard let section = items.element(at: section), let item = section.element(at: indexPath.item) else {
            completion(nil)
            return
        }
        
        AvatarManager.shared.avatar(for: item.avatarPath, completion: { image, _ in
            completion(image)
        })
    }
    
    @objc private func reload(searchText: String) {
        
        if
            let possibleURLString = searchText.asPossibleURLString,
            possibleURLString.isValidURL {
                let title = NSAttributedString(string: possibleURLString, attributes: openButtonAttributes)
                openURLButton.setAttributedTitle(title)
            
                searchResultView.searchResults = []
            
                showOpenURLButton()
        } else {
            hideOpenURLButtonIfNeeded()
            IDAPIClient.shared.searchContacts(name: searchText) { [weak self] users in
                
                if let searchBarText = self?.searchBar.text, searchText == searchBarText {
                    self?.searchResultView.searchResults = users
                }
            }
        }
    }
    
    private func showOpenURLButton() {
        openURLButton.isHidden = false
        openURLButtonTopAnchor?.constant = topInset
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 10, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func hideOpenURLButtonIfNeeded(animated: Bool = true) {
        openURLButtonTopAnchor?.constant = 0

        guard animated else {
            self.openURLButton.isHidden = true
            return
        }

        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.openURLButton.setAttributedTitle(nil)
            self.openURLButton.isHidden = true
        })
    }
    
    @objc private func didTapOpenURL(_ button: UIControl) {
        guard
            let searchText = searchController.searchBar.text,
            let possibleURLString = searchText.asPossibleURLString,
            let url = URL(string: possibleURLString)
            else { return }
        
        let sofaController = SOFAWebController()
        
        sofaController.load(url: url)

        dismissSearch()
        navigationController?.pushViewController(sofaController, animated: true)
    }
    
    private func clearSearch() {
        searchBar.setShowsCancelButton(false, animated: true)
        searchResultView.isHidden = true
        searchResultView.searchResults = []
    }
}

extension BrowseViewController: UISearchBarDelegate {
    
    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        
        searchResultView.isHidden = false
        
        if searchText.isEmpty {
            searchResultView.searchResults = []
            hideOpenURLButtonIfNeeded()
        }
        
        reload(searchText: searchText)
    }
    
    func searchBarCancelButtonClicked(_: UISearchBar) {
        clearSearch()
        hideOpenURLButtonIfNeeded()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let sectionedCollectionView = collectionView as? SectionedCollectionView {
            let cell = sectionedCollectionView.dequeue(BrowseEntityCollectionViewCell.self, for: indexPath)
            
            if let section = items.element(at: sectionedCollectionView.section), let item = section.element(at: indexPath.item) {
                cell.nameLabel.text = item.nameForBrowseAndSearch
                cell.imageViewPath = item.avatarPath

                cell.ratingView.isHidden = !item.shouldShowRating
                if let averageRating = item.rating {
                    cell.ratingView.set(rating: averageRating)
                }
            }
            
            return cell
        }
        
        let contentSection = contentSections[indexPath.item]
        
        let cell = collectionView.dequeue(BrowseCollectionViewCell.self, for: indexPath)
        cell.collectionView.dataSource = self
        cell.collectionView.reloadData()
        cell.collectionView.collectionViewLayout.invalidateLayout()
        cell.collectionView.section = indexPath.item
        cell.contentSection = contentSection
        cell.collectionViewDelegate = self
        cell.divider.isHidden = contentSection == .latestPublicUsers
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        
        if let collectionView = collectionView as? SectionedCollectionView {
            return items[collectionView.section].count
        }
        
        return items.count
    }
}

extension BrowseViewController {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItems = items[indexPath.row].count
        let itemHeight: CGFloat = (numberOfItems == 0) ? 0 : 247
        
        return CGSize(width: UIScreen.main.bounds.width, height: itemHeight)
    }
}

extension BrowseViewController: BrowseCollectionViewCellSelectionDelegate {
    
    func seeAll(for contentSection: BrowseContentSection) {
        let controller = BrowseAllViewController(contentSection)
        controller.title = contentSection.title
        Navigator.push(controller)
    }
    
    func didSelectItem(at indexPath: IndexPath, collectionView: SectionedCollectionView) {
        if let section = items.element(at: collectionView.section) {
            dismissSearch()

            if let user = section.element(at: indexPath.item) as? TokenUser {
                Navigator.push(ProfileViewController(profile: user))
            } else if let dapp = section.element(at: indexPath.item) as? Dapp {
                Navigator.push(DappViewController(with: dapp))
            } else {
                assertionFailure("Unhandled element type at index path \(indexPath)")
            }
        }
    }
}

extension BrowseViewController: SearchSelectionDelegate {

    func didSelectSearchResult(user: TokenUser) {
        dismissSearch()
        Navigator.push(ProfileViewController(profile: user))
    }
}
