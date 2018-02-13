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

final class ReputationView: UIView {
    
    var reviewCount: Int = 0 {
        didSet {
            ratingsCountLabel.text = LocalizedPlural("ratings_count", for: reviewCount)
        }
    }
    
    private lazy var ratingLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.light(size: 49)
        label.textColor = Theme.ratingTint
        label.textAlignment = .center
        
        return label
    }()
    
    private lazy var ratingView: RatingView = {
        let view = RatingView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    private lazy var ratingsCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.lightGreyTextColor
        label.font = Theme.regular(size: 14)
        
        return label
    }()
    
    private lazy var reputationBarViews = [ReputationBarView(), ReputationBarView(), ReputationBarView(), ReputationBarView(), ReputationBarView()]
    private lazy var guides = [UILayoutGuide(), UILayoutGuide()]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let horizontalMargin: CGFloat = 16
        let barHeight: CGFloat = 18
        let barSpacing: CGFloat = 2
        
        addSubview(ratingLabel)
        addSubview(ratingView)
        addSubview(ratingsCountLabel)
        guides.forEach { addLayoutGuide($0) }
        reputationBarViews.forEach { addSubview($0) }
        
        let firstGuide = guides[0]
        firstGuide.top(to: self)
        firstGuide.left(to: self)
        firstGuide.bottom(to: self)
        
        let secondGuide = guides[1]
        secondGuide.top(to: self)
        secondGuide.leftToRight(of: firstGuide)
        secondGuide.bottom(to: self)
        secondGuide.right(to: self)
        
        ratingLabel.top(to: firstGuide, offset: 5)
        ratingLabel.left(to: firstGuide, offset: horizontalMargin)
        ratingLabel.right(to: firstGuide, offset: -horizontalMargin)
        
        ratingView.topToBottom(of: ratingLabel, offset: 0)
        ratingView.centerX(to: firstGuide)
        
        ratingsCountLabel.topToBottom(of: ratingView, offset: 10)
        ratingsCountLabel.centerX(to: firstGuide)
        ratingsCountLabel.bottom(to: firstGuide, offset: -barSpacing)
        ratingsCountLabel.height(16)
        
        var previousReputationBarView: ReputationBarView? = nil
        
        reputationBarViews.forEach {
            if let previousReputationBarView = previousReputationBarView {
                $0.topToBottom(of: previousReputationBarView, offset: barSpacing)
            } else {
                $0.top(to: secondGuide, offset: barSpacing)
            }
            
            $0.left(to: secondGuide, offset: horizontalMargin)
            $0.right(to: self)
            $0.height(barHeight)
            
            if let lastBarView = reputationBarViews.last, lastBarView == $0 {
                $0.bottom(to: secondGuide, offset: barSpacing)
            }
            
            previousReputationBarView = $0
        }
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setScore(_ ratingScore: RatingScore) {
        reviewCount = ratingScore.reviewCount
        ratingLabel.text = "\(ratingScore.averageRating)"
        ratingView.set(rating: Float(ratingScore.averageRating))
        
        let count = ratingScore.reviewCount == 0 ? 1 : ratingScore.reviewCount
        
        reputationBarViews[0].numberOfStars = 5
        reputationBarViews[0].percentage = CGFloat(ratingScore.stars.five) / CGFloat(count)
        
        reputationBarViews[1].numberOfStars = 4
        reputationBarViews[1].percentage = CGFloat(ratingScore.stars.four) / CGFloat(count)
        
        reputationBarViews[2].numberOfStars = 3
        reputationBarViews[2].percentage = CGFloat(ratingScore.stars.three) / CGFloat(count)
        
        reputationBarViews[3].numberOfStars = 2
        reputationBarViews[3].percentage = CGFloat(ratingScore.stars.two) / CGFloat(count)
        
        reputationBarViews[4].numberOfStars = 1
        reputationBarViews[4].percentage = CGFloat(ratingScore.stars.one) / CGFloat(count)
    }
}
