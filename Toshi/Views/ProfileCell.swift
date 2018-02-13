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

final class ProfileCell: UITableViewCell {
    
    // MARK: - Properties for configuration
    
    static let reuseIdentifier = "ProfileCell"
    
    var avatarPath: String? {
        didSet {
            guard let path = avatarPath else { return }
            
            AvatarManager.shared.avatar(for: path) { [weak self] image, retrievedPath in
                if image != nil && self?.avatarPath == retrievedPath {
                    self?.avatarImageView.image = image
                }
            }
        }
    }
    
    var name: String? {
        didSet {
            if let name = name, !name.isEmpty {
                nameLabel.text = name
            }
        }
    }
    
    var displayUsername: String? {
        didSet {
            usernameLabel.text = displayUsername
        }
    }
    
    // MARK: - Lazy Vars

    private lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.darkTextColor
        view.font = Theme.preferredSemibold()
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    private lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.greyTextColor
        view.font = Theme.preferredRegularSmall()
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    private lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    private lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    private lazy var checkmarkView: Checkbox = {
        let checkbox = Checkbox(frame: CGRect(origin: .zero, size: CGSize(width: 38, height: 38)))
        checkbox.checked = false
        return checkbox
    }()
    
    // MARK: - Checkmark helpers
    
    var isCheckmarkShowing: Bool {
        get {
            return !checkmarkView.isHidden
        }
        set {
            checkmarkView.isHidden = !newValue
        }
    }
    
    var isCheckmarkChecked: Bool {
        get {
            return checkmarkView.checked
        }
        set {
            checkmarkView.checked = newValue
        }
    }

    // MARK: - Initialization
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(checkmarkView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(separatorView)

        let margin: CGFloat = 16.0
        let interLabelMargin: CGFloat = 6.0
        let imageSize: CGFloat = 48.0
        let height: CGFloat = 24.0

        avatarImageView.size(CGSize(width: imageSize, height: imageSize))
        avatarImageView.centerY(to: contentView)
        avatarImageView.left(to: contentView, offset: margin)

        checkmarkView.centerY(to: contentView)
        checkmarkView.right(to: contentView, offset: -margin)
        checkmarkView.layer.borderColor = UIColor.red.cgColor
        isCheckmarkShowing = false
        
        nameLabel.height(height, relation: .equalOrGreater)
        nameLabel.top(to: contentView, offset: margin)
        nameLabel.leftToRight(of: avatarImageView, offset: 10)
        nameLabel.rightToLeft(of: checkmarkView, offset: -margin)

        usernameLabel.height(height, relation: .equalOrGreater)
        usernameLabel.topToBottom(of: nameLabel)
        usernameLabel.leftToRight(of: avatarImageView, offset: 10)
        usernameLabel.rightToLeft(of: checkmarkView, offset: -margin)

        separatorView.height(.lineHeight)
        separatorView.topToBottom(of: usernameLabel, offset: interLabelMargin)
        separatorView.left(to: contentView, offset: margin)
        separatorView.bottom(to: contentView)
        separatorView.right(to: contentView, offset: -margin)
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }
    
    // MARK: - Recycling
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        avatarImageView.image = nil
        avatarPath = nil
        nameLabel.text = nil
        name = nil
        usernameLabel.text = nil
        displayUsername = nil
    }
}
