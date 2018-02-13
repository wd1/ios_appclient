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
import SweetUIKit
import TinyConstraints

final class ReputationBarView: UIView {
    
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.greyTextColor
        label.font = Theme.medium(size: 13)
        
        return label
    }()
    
    private lazy var starImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "gray-star"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    private lazy var barView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.ratingTint
        view.layer.cornerRadius = 2.0
        
        return view
    }()
    
    var numberOfStars: Int = 0 {
        didSet {
            numberLabel.text = String(describing: numberOfStars)
        }
    }
    
    var percentage: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    var barWidthAnchor: NSLayoutConstraint?
    let totalWidth: CGFloat = 180
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(numberLabel)
        addSubview(starImageView)
        addSubview(barView)
        
        numberLabel.top(to: self)
        numberLabel.left(to: self)
        numberLabel.bottom(to: self)
        numberLabel.width(8)
        
        starImageView.centerY(to: self)
        starImageView.leftToRight(of: numberLabel, offset: 5)
        
        barView.top(to: self)
        barView.leftToRight(of: starImageView, offset: 8)
        barView.bottom(to: self)
        
        barWidthAnchor = barView.width(totalWidth)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let barRightMargin: CGFloat = 11
        let startAndCountWidth: CGFloat = 21
        let width = bounds.size.width - startAndCountWidth
        
        barWidthAnchor?.constant = min((width - barRightMargin), (percentage * width))
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
