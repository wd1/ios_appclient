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

final class GroupViewController: UIViewController {

    private var configurator: CellConfigurator
    private var viewModel: GroupViewModelProtocol

    private lazy var activityView = self.defaultActivityIndicator()

    var scrollViewBottomInset: CGFloat = 0.0

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

    fileprivate lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .grouped)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = nil
        view.isOpaque = false
        BasicTableViewCell.register(in: view)
        view.delegate = self
        view.dataSource = self
        view.tableFooterView = UIView()
        view.layer.borderWidth = .lineHeight
        view.layer.borderColor = Theme.borderColor.cgColor
        view.alwaysBounceVertical = true

        return view
    }()

    init(_ viewModel: GroupViewModelProtocol, configurator: CellConfigurator) {
        self.viewModel = viewModel

        self.configurator = configurator
        super.init(nibName: nil, bundle: nil)

        self.viewModel.completeActionDelegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        preferLargeTitleIfPossible(false)

        view.backgroundColor = Theme.lightGrayBackgroundColor
        title = viewModel.viewControllerTitle

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: viewModel.rightBarButtonTitle, style: .plain, target:
            viewModel, action: viewModel.rightBarButtonSelector)
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([.font: Theme.bold(size: 17.0), .foregroundColor: Theme.tintColor], for: .normal)

        addSubviewsAndConstraints()
        setupActivityIndicator()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(false)

        registerForKeyboardNotifications()
        adjustDoneButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        scrollViewBottomInset = tableView.contentInset.bottom

        if (viewModel as? NewGroupViewModel) != nil {
           letGroupTitleCellBecomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        unregisterFromKeyboardNotifications()
    }

    func addSubviewsAndConstraints() {
        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        activityIndicator.set(height: 50.0)
        activityIndicator.set(width: 50.0)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func letGroupTitleCellBecomeFirstResponder() {
        if let titleCell = tableView.visibleCells.first as? AvatarTitleCell {
            titleCell.titleTextField.becomeFirstResponder()
        }
    }

    @objc func updateAvatar() {
        let pickerTypeAlertController = UIAlertController(title: viewModel.imagePickerTitle, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: viewModel.imagePickerCameraActionTitle, style: .default) { _ in
            self.presentImagePicker(sourceType: .camera)
        }

        let libraryAction = UIAlertAction(title: viewModel.imagePickerLibraryActionTitle, style: .default) { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        }

        let cancelAction = UIAlertAction(title: viewModel.imagePickerCancelActionTitle, style: .cancel, handler: nil)

        pickerTypeAlertController.addAction(cameraAction)
        pickerTypeAlertController.addAction(libraryAction)
        pickerTypeAlertController.addAction(cancelAction)

        present(pickerTypeAlertController, animated: true)
    }

    func changeAvatar(to avatar: UIImage?) {
        if let avatar = avatar {
            viewModel.updateAvatar(to: avatar)
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
    }

    @objc func cancelAndDismiss() {
        navigationController?.popViewController(animated: true)
    }

    fileprivate func completeEdit(success: Bool, message: String?) {
        activityIndicator.stopAnimating()

        if success == true {
            navigationController?.popViewController(animated: true)
        } else {
            let alert = UIAlertController.dismissableAlert(title: viewModel.errorAlertTitle, message: message ?? viewModel.errorAlertMessage)
            Navigator.presentModally(alert)
        }
    }

    @objc private func didTapView(sender: UITapGestureRecognizer) {
        if sender.state == .recognized {
            becomeFirstResponder()
        }
    }

    private func adjustDoneButton() {
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.isDoneButtonEnabled
    }

    private func showUserInfo(with userId: String) {
        guard let currentUser = TokenUser.current else { return }
        var users = SessionManager.shared.contactsManager.tokenContacts.filter { $0.address == userId }
        users.append(currentUser)

        guard let user = users.first else { return }
        let profileController = ProfileViewController(profile: user)
        navigationController?.pushViewController(profileController, animated: true)
    }

    private func presentExitGroupAlert() {
        let alertController = UIAlertController(title: nil, message: Localized("group_info_leave_confirmation_message"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Localized("cancel_action_title"), style: .cancel, handler: nil))

        let exitAction = UIAlertAction(title: Localized("group_info_leave_action_title"), style: .destructive) { _ in
            self.exitGroup()
        }

        alertController.addAction(exitAction)

        present(alertController, animated: true, completion: nil)
    }

    private func exitGroup() {
        guard let group = viewModel.groupThread else { return }

        showActivityIndicator()
        
        ChatInteractor.sendLeaveGroupMessage(group, completion: { [weak self] success in

            self?.hideActivityIndicator()

            if success {
                self?.navigationController?.popToRootViewController(animated: true)
            } else {
                let alertController = UIAlertController.dismissableAlert(title: Localized("error_title"), message: Localized("group_info_leave_group_failure_message"))
                self?.present(alertController, animated: true, completion: nil)
            }
        })
    }
}

extension GroupViewController: ActivityIndicating {
    var activityIndicator: UIActivityIndicatorView {
        return activityView
    }
}

extension GroupViewController: KeyboardAdjustable {

    var scrollView: UIScrollView {
        return tableView
    }
}

extension GroupViewController: GroupViewModelCompleteActionDelegate {

    func groupViewModelDidStartCreateOrUpdate() {
        view.endEditing(true)

        showActivityIndicator()
    }

    func groupViewModelDidFinishCreateOrUpdate() {

        hideActivityIndicator()

        guard viewModel is NewGroupViewModel else {
            self.navigationController?.popViewController(animated: true)
            return
        }

        navigationController?.popToRootViewController(animated: true)

        Navigator.topViewController?.dismiss(animated: false, completion: nil)
    }

    func groupViewModelDidRequireReload(_ viewModel: GroupViewModelProtocol) {
        tableView.reloadData()
    }
}

extension GroupViewController: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {

        picker.dismiss(animated: true, completion: nil)

        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else {
            return
        }

        changeAvatar(to: image)
    }
}

extension GroupViewController: UITableViewDelegate {

    public func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let sectionData = viewModel.sectionModels[indexPath.section]
        let cellData = sectionData.cellsData[indexPath.row]

        guard let tag = cellData.tag, let itemType = GroupItemType(rawValue: tag) else { return }

        switch itemType {
        case .participant:
            let selectedUserId = viewModel.allParticipantsIDs[indexPath.row - 1]
            showUserInfo(with: selectedUserId)
        case .addParticipant:
            let datasource = ProfilesDataSource(type: .updateGroupChat)
            datasource.excludedProfilesIds = viewModel.recipientsIds
            let profilesViewController = ProfilesViewController(datasource: datasource, output: self)

            navigationController?.pushViewController(profilesViewController, animated: true)
        case .exitGroup:
            presentExitGroupAlert()
        default:
            break
        }
    }
}

extension GroupViewController: UINavigationControllerDelegate {

    private func presentImagePicker(sourceType: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = true
        imagePicker.delegate = self

        present(imagePicker, animated: true)
    }
}

extension GroupViewController: ProfilesListCompletionOutput {

    func didFinish(_ controller: ProfilesViewController, selectedProfilesIds: [String]) {
        viewModel.updateRecipientsIds(to: selectedProfilesIds)
    }
}

extension GroupViewController: UITableViewDataSource {

    public func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionData = viewModel.sectionModels[section]
        return sectionData.headerTitle
    }

    public func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
        let sectionData = viewModel.sectionModels[section]
        return sectionData.footerTitle
    }

    public func numberOfSections(in _: UITableView) -> Int {
        return viewModel.sectionModels.count
    }

    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionData = viewModel.sectionModels[section]
        return sectionData.cellsData.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let sectionData = viewModel.sectionModels[indexPath.section]
        let cellData = sectionData.cellsData[indexPath.row]

        let reuseIdentifier = configurator.cellIdentifier(for: cellData.components)

        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? BasicTableViewCell else { return UITableViewCell(frame: .zero) }
        configurator.configureCell(cell, with: cellData)
        cell.actionDelegate = self

        return cell
    }
}

extension GroupViewController: BasicCellActionDelegate {

    func didChangeSwitchState(_ cell: BasicTableViewCell, _ state: Bool) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        let sectionData = viewModel.sectionModels[indexPath.section]
        let cellData = sectionData.cellsData[indexPath.row]

        guard let tag = cellData.tag, let itemType = GroupItemType(rawValue: tag) else { return }

        switch itemType {
        case .notifications:
            viewModel.updateNotificationsState(to: state)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        default:
            break
        }
    }

    func didTapLeftImage(_ cell: BasicTableViewCell) {
        cell.titleTextField.resignFirstResponder()
        updateAvatar()
    }

    func didFinishTitleInput(_ cell: BasicTableViewCell, text: String?) {
        let title = text?.trimmingCharacters(in: .whitespaces) ?? ""
        viewModel.updateTitle(to: title)
    }

    func titleShouldChangeCharactersInRange(_ cell: BasicTableViewCell, text: String?, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let resultText = (text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
        viewModel.updateTitle(to: resultText)
        adjustDoneButton()

        return true
    }
}
