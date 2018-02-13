import Foundation
import UIKit
import TinyConstraints
import SweetUIKit

final class ProfilesHeaderView: UIView {
    
    private let type: ProfilesViewControllerType
    private let searchBar: UISearchBar?
    private(set) var addedHeader: ProfilesAddedToGroupHeader?
    
    required init(with searchBar: UISearchBar? = nil, type: ProfilesViewControllerType, delegate: ProfilesAddGroupHeaderDelegate?) {
        self.type = type
        self.searchBar = searchBar
        super.init(frame: .zero)
                
        if #available(iOS 11, *) {
            width(UIScreen.main.bounds.width)
        }
        
        configure(for: type, with: delegate, searchBar: searchBar)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(for type: ProfilesViewControllerType, with delegate: ProfilesAddGroupHeaderDelegate?, searchBar: UISearchBar?) {
        switch type {
        case .favorites:
            if #available(iOS 11, *) {
                // Do nothing, search bar should already be set up
            } else {
                frame = CGRect(origin: .zero, size: (searchBar?.frame.size ?? .zero))
                addSearchBar(searchBar)
            }
        case .newChat:
            let addGroupHeader = ProfilesAddGroupHeader(with: delegate)
            addSubview(addGroupHeader)
            
            let groupHeaderHeight: CGFloat = 70
            
            if #available(iOS 11, *) {
                height(groupHeaderHeight)
                addGroupHeader.edgesToSuperview()
            } else {
                frame = CGRect(origin: .zero, size: CGSize(width: (searchBar?.frame.size.width ?? 0), height: (searchBar?.frame.size.height ?? 0) + groupHeaderHeight))
                addSearchBar(searchBar)
                addGroupHeader.edgesToSuperview(excluding: .top)
                addGroupHeader.height(groupHeaderHeight)
            }
        case .newGroupChat, .updateGroupChat:
            let addedToGroupHeader = ProfilesAddedToGroupHeader(margin: 16)
            addSubview(addedToGroupHeader)
            addedHeader = addedToGroupHeader
            
            if #available(iOS 11, *) {
                addedToGroupHeader.edgesToSuperview()
            } else {
                let eyeballedFrameHeight: CGFloat = 60
                frame = CGRect(origin: .zero, size: CGSize(width: (searchBar?.frame.width ?? 0), height: (searchBar?.frame.height ?? 0) + eyeballedFrameHeight))
                addSearchBar(searchBar)
                let searchBarHeight = searchBar?.frame.height ?? 0
                addedToGroupHeader.edgesToSuperview(insets: UIEdgeInsets(top: searchBarHeight, left: 0, bottom: 0, right: 0))
            }
        }
    }
    
    private func addSearchBar(_ searchBar: UISearchBar?) {
        guard let searchBar = searchBar else {
            assertionFailure("Search bar should be passed in for iOS 10!")
            
            return
        }
        
        searchBar.frame.origin = .zero
        
        // Note: Autolayout does not play nicely with the search bar.
        addSubview(searchBar)
    }
}
