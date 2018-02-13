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

import SweetUIKit

class Checkbox: UIView {

    static let size: CGFloat = 20

    private lazy var unCheckedView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.isUserInteractionEnabled = false

        let layer = CAShapeLayer()
        layer.fillColor = UIColor.white.cgColor
        layer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: Checkbox.size, height: Checkbox.size)).cgPath
        layer.strokeColor = Theme.borderColor.cgColor
        layer.lineWidth = 1
        view.layer.addSublayer(layer)

        return view
    }()

    private lazy var checkedView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.isUserInteractionEnabled = false

        let layer = CAShapeLayer()
        layer.fillColor = Theme.tintColor.cgColor
        layer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: Checkbox.size, height: Checkbox.size)).cgPath
        layer.strokeColor = Theme.tintColor.cgColor
        layer.lineWidth = 1
        view.layer.addSublayer(layer)

        let imageView = UIImageView(withAutoLayout: true)
        imageView.isUserInteractionEnabled = false
        imageView.contentMode = .center
        imageView.image = #imageLiteral(resourceName: "checkmark").withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Theme.viewBackgroundColor
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])

        return view
    }()

    var checked: Bool = false {
        didSet {
            self.unCheckedView.isHidden = checked
            self.checkedView.isHidden = !checked
        }
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(unCheckedView)
        addSubview(checkedView)

        NSLayoutConstraint.activate([
            self.unCheckedView.topAnchor.constraint(equalTo: self.topAnchor),
            self.unCheckedView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.unCheckedView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.unCheckedView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.unCheckedView.widthAnchor.constraint(equalToConstant: Checkbox.size),
            self.unCheckedView.heightAnchor.constraint(equalToConstant: Checkbox.size)
        ])

        NSLayoutConstraint.activate([
            self.checkedView.topAnchor.constraint(equalTo: self.topAnchor),
            self.checkedView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.checkedView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.checkedView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.checkedView.widthAnchor.constraint(equalToConstant: Checkbox.size),
            self.checkedView.heightAnchor.constraint(equalToConstant: Checkbox.size)
        ])
    }
}
