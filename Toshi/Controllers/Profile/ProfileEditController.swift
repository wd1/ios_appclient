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
import SweetFoundation

class ProfileEditController: UIViewController, KeyboardAdjustable, UINavigationControllerDelegate {

    private static let profileVisibilitySectionTitle = Localized("edit_profile_visibility_section_title")
    private static let profileVisibilitySectionFooter = Localized("edit_profile_visibility_section_explanation")

    var scrollViewBottomInset: CGFloat = 0.0

    var scrollView: UIScrollView {
        return tableView
    }

    var keyboardWillShowSelector: Selector {
        return #selector(keyboardShownNotificationReceived(_:))
    }

    var keyboardWillHideSelector: Selector {
        return #selector(keyboardHiddenNotificationReceived(_:))
    }

    @objc private func keyboardShownNotificationReceived(_ notification: NSNotification) {
        keyboardWillShow(notification)
    }

    @objc private func keyboardHiddenNotificationReceived(_ notification: NSNotification) {
        keyboardWillHide(notification)
    }

    private let editingSections = [ProfileEditSection(items: [ProfileEditItem(.username), ProfileEditItem(.displayName), ProfileEditItem(.about), ProfileEditItem(.location)]),
                                       ProfileEditSection(items: [ProfileEditItem(.visibility)], headerTitle: profileVisibilitySectionTitle, footerTitle: profileVisibilitySectionFooter)]

    private var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    private lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    private lazy var changeAvatarButton: UIButton = {
        let view = UIButton(withAutoLayout: true)

        let title = NSAttributedString(string: Localized("edit_profile_change_photo"), attributes: [.foregroundColor: Theme.tintColor, .font: Theme.preferredRegularMedium()])
        view.setAttributedTitle(title, for: .normal)
        view.titleLabel?.adjustsFontForContentSizeCategory = true
        view.addTarget(self, action: #selector(updateAvatar), for: .touchUpInside)

        return view
    }()

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .grouped)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = nil
        view.isOpaque = false
        view.register(InputCell.self)
        view.delegate = self
        view.dataSource = self
        view.tableFooterView = UIView()
        view.register(UINib(nibName: "InputCell", bundle: nil), forCellReuseIdentifier: String(describing: InputCell.self))
        view.layer.borderWidth = .lineHeight
        view.layer.borderColor = Theme.borderColor.cgColor
        view.alwaysBounceVertical = true

        return view
    }()

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Theme.lightGrayBackgroundColor
        title = Localized("edit_profile_title")

        guard let user = TokenUser.current else { return }

        AvatarManager.shared.avatar(for: user.avatarPath) { [weak self] image, _ in
            self?.avatarImageView.image = image
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapView))
        view.addGestureRecognizer(tapGesture)

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelAndDismiss))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.saveAndDismiss))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([.font: Theme.bold(size: 17.0), .foregroundColor: Theme.tintColor], for: .normal)

        addSubviewsAndConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        registerForKeyboardNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        scrollViewBottomInset = tableView.contentInset.bottom
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        unregisterFromKeyboardNotifications()
    }

    private lazy var headerView: UIView = {
        let view = UIView(frame: CGRect.zero)

        view.backgroundColor = nil
        view.isOpaque = false
        
        view.addSubview(self.avatarImageView)
        view.addSubview(self.changeAvatarButton)

        let bottomBorder = UIView(withAutoLayout: true)
        view.addSubview(bottomBorder)

        bottomBorder.backgroundColor = Theme.borderColor
        bottomBorder.set(height: .lineHeight)
        bottomBorder.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bottomBorder.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        bottomBorder.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        self.avatarImageView.set(height: 80)
        self.avatarImageView.set(width: 80)
        self.avatarImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 24).isActive = true
        self.avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        self.changeAvatarButton.set(height: 38)
        self.changeAvatarButton.topAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor, constant: 12).isActive = true
        self.changeAvatarButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24).isActive = true
        self.changeAvatarButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        view.layoutIfNeeded()

        return view
    }()

    func addSubviewsAndConstraints() {
        let height = headerView.systemLayoutSizeFitting(UILayoutFittingExpandedSize).height

        var headerFrame = headerView.frame
        headerFrame.size.height = height
        headerView.frame = headerFrame

        tableView.tableHeaderView = headerView

        view.addSubview(tableView)

        view.addSubview(self.activityIndicator)

        self.activityIndicator.set(height: 50.0)
        self.activityIndicator.set(width: 50.0)
        self.activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        tableView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    @objc func updateAvatar() {
        let pickerTypeAlertController = UIAlertController(title: Localized("image-picker-select-source-title"), message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: Localized("image-picker-camera-action-title"), style: .default) { _ in
            self.presentImagePicker(sourceType: .camera)
        }

        let libraryAction = UIAlertAction(title: Localized("image-picker-library-action-title"), style: .default) { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        }

        let cancelAction = UIAlertAction(title: Localized("cancel_action_title"), style: .cancel, handler: nil)

        pickerTypeAlertController.addAction(cameraAction)
        pickerTypeAlertController.addAction(libraryAction)
        pickerTypeAlertController.addAction(cancelAction)

        present(pickerTypeAlertController, animated: true)
    }

    private func presentImagePicker(sourceType: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = true
        imagePicker.delegate = self

        present(imagePicker, animated: true)
    }

    func changeAvatar(to avatar: UIImage?) {
        if let avatar = avatar {
            let scaledImage = avatar.resized(toHeight: 320)
            avatarImageView.image = scaledImage
        }
    }

    @objc func cancelAndDismiss() {
        navigationController?.popViewController(animated: true)
    }

    @objc func saveAndDismiss() {
        guard let user = TokenUser.current else { return }

        var username = ""
        var name = ""
        var about = ""
        var location = ""
        var isPublic = false

        // we use flatmap here to map nested array into one
        let editedItems = editingSections.flatMap { section in
            return section.items
        }

        editedItems.forEach { item in
            let text = item.detailText

            switch item.type {
            case .username:
                username = text
            case .displayName:
                name = text
            case .about:
                about = text
            case .location:
                location = text
            case .visibility:
                isPublic = item.switchMode
            default:
                break
            }
        }

        view.endEditing(true)

        if validateUserName(username) == false {
            let alert = UIAlertController.dismissableAlert(title: Localized("error-alert-title"), message: Localized("invalid-username-alert-message"))
            Navigator.presentModally(alert)

            return
        }

        activityIndicator.startAnimating()

        let userDict: [String: Any] = [
            TokenUser.Constants.address: user.address,
            TokenUser.Constants.paymentAddress: user.paymentAddress,
            TokenUser.Constants.username: username,
            TokenUser.Constants.about: about,
            TokenUser.Constants.location: location,
            TokenUser.Constants.name: name,
            TokenUser.Constants.avatar: user.avatarPath,
            TokenUser.Constants.isApp: user.isApp,
            TokenUser.Constants.isPublic: isPublic,
            TokenUser.Constants.verified: user.verified
        ]

        idAPIClient.updateUser(userDict) { [weak self] userUpdated, error in

            let cachedAvatar = AvatarManager.shared.cachedAvatar(for: user.avatarPath)

            if let image = self?.avatarImageView.image, image != cachedAvatar {

                self?.idAPIClient.updateAvatar(image) { [weak self] avatarUpdated, error in
                    let success = userUpdated == true && avatarUpdated == true

                    self?.completeEdit(success: success, message: error?.description)
                }
            } else {
                self?.completeEdit(success: userUpdated, message: error?.description)
            }
        }
    }

    private func validateUserName(_ username: String) -> Bool {
        let none = NSRegularExpression.MatchingOptions(rawValue: 0)
        let range = NSRange(location: 0, length: username.count)

        var isValid = true

        if isValid {
            isValid = username.count >= 2
        }

        if isValid {
            isValid = username.count <= 60
        }

        var regex: NSRegularExpression?
        do {
            let pattern = IDAPIClient.usernameValidationPattern
            regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines, .dotMatchesLineSeparators, .useUnicodeWordBoundaries])
        } catch {
            fatalError("Invalid regular expression pattern")
        }

        if isValid {
            if let validationRegex = regex {
                isValid = validationRegex.numberOfMatches(in: username, options: none, range: range) >= 1
            }
        }

        return isValid
    }

    private func completeEdit(success: Bool, message: String?) {
        activityIndicator.stopAnimating()

        if success == true {
            navigationController?.popViewController(animated: true)
        } else {
            let alert = UIAlertController.dismissableAlert(title: Localized("error_title"), message: message ?? Localized("toshi_generic_error"))
            Navigator.presentModally(alert)
        }
    }

    @objc private func didTapView(sender: UITapGestureRecognizer) {
        if sender.state == .recognized {
            becomeFirstResponder()
        }
    }

    private lazy var activityIndicator: UIActivityIndicatorView = {
        // need to initialize with large style which is available only white, thus need to set color later
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.color = Theme.lightGreyTextColor
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        return activityIndicator
    }()
}

extension ProfileEditController: UIImagePickerControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {

        picker.dismiss(animated: true, completion: nil)

        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else {
            return
        }

        self.changeAvatar(to: image)
    }
}

extension ProfileEditController: UITableViewDelegate {

    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension ProfileEditController: UITableViewDataSource {

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? ProfileEditController.profileVisibilitySectionTitle : nil
    }

    func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
        let editingSection = editingSections[section]

        return editingSection.footerTitle
    }

    func numberOfSections(in _: UITableView) -> Int {
        return editingSections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let editingSection = editingSections[section]

        return editingSection.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(InputCell.self, for: indexPath)

        let section = editingSections[indexPath.section]
        let item = section.items[indexPath.row]

        let configurator = ProfileEditConfigurator(item: item)
        configurator.configure(cell: cell)

        return cell
    }
}
