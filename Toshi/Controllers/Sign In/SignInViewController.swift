import Foundation
import UIKit
import TinyConstraints

protocol SignInViewControllerDelegate: class {
    func didRequireNewAccountCreation(_ controller: SignInViewController)
}

final class SignInViewController: UIViewController {

    private var signInView: SignInView? { return view as? SignInView }
    private lazy var activityView: UIActivityIndicatorView = self.defaultActivityIndicator()

    weak var delegate: SignInViewControllerDelegate?

    private var enteredStrings: [String] = [""]
    private var itemCount: Int = 1
    static let maxItemCount: Int = 12
    private var shouldDeselectWord = false
    private var userDidPastePassphrase = false
    
    var activeIndexPath: IndexPath? {
        guard let selectedCell = signInView?.collectionView.visibleCells.first(where: { $0.isSelected }) else { return nil }
        return signInView?.collectionView.indexPath(for: selectedCell)
    }

    var activeCell: SignInCell? {
        guard let activeIndexPath = activeIndexPath else { return nil }
        return signInView?.collectionView.cellForItem(at: activeIndexPath) as? SignInCell
    }

    override func loadView() {
        view = SignInView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInView?.collectionView.delegate = self
        signInView?.collectionView.dataSource = self
        signInView?.textField.delegate = self
        signInView?.textField.deleteDelegate = self

        setupActivityIndicator()
        
        signInView?.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .top)

        signInView?.footerView.explanationButton.addTarget(self, action: #selector(showExplanation(_:)), for: .touchUpInside)
        signInView?.footerView.signInButton.addTarget(self, action: #selector(signIn(_:)), for: .touchUpInside)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(_:)))
        longPressGestureRecognizer.minimumPressDuration = 0.3
        longPressGestureRecognizer.cancelsTouchesInView = true
        longPressGestureRecognizer.delegate = self
        signInView?.addGestureRecognizer(longPressGestureRecognizer)

        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        signInView?.textField.becomeFirstResponder()
    }

    @objc private func appDidBecomeActive(_ notification: Notification) {
        if isViewLoaded {
            signInView?.textField.becomeFirstResponder()
        }
    }

    @objc private func showExplanation(_ button: UIButton) {
        let explanationViewController = SignInExplanationViewController()
        navigationController?.pushViewController(explanationViewController, animated: true)
    }
    
    @objc private func longPressGestureRecognized(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        
        let indexPath = activeIndexPath ?? IndexPath(item: 0, section: 0)
        showTextEditingOptions(for: indexPath)
    }

    @objc private func signIn(_ button: ActionButton) {
        guard let collectionView = signInView?.collectionView else { return }

        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: false)
        }

        let indexPaths = collectionView.indexPathsForVisibleItems.sorted {$0.item < $1.item}
        let cells = indexPaths.flatMap { collectionView.cellForItem(at: $0) as? SignInCell }
        let passphrase = cells.flatMap { $0.match }

        signInWithPasshphrase(passphrase)
    }

    private func signInWithPasshphrase(_ passphrase: [String]) {

        signInView?.textField.resignFirstResponder()

        showActivityIndicator()

        SessionManager.shared.signInUser(passphrase) { [weak self] result in
            guard let strongSelf = self else { return }

            strongSelf.hideActivityIndicator()

            switch result {
            case .signUpWithPassphrase:
                let alertController = UIAlertController(title: Localized("sign_up_with_passphrase_alert_title"), message: Localized("sign_up_with_passphrase_alert_message"), preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: Localized("cancel_action_title"), style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: Localized("sign_up_with_passphrase_accept_action_title"), style: .default, handler: { _ in
                    guard let validCereal = Cereal(words: passphrase) else { return }
                    Cereal.shared = validCereal

                    strongSelf.delegate?.didRequireNewAccountCreation(strongSelf)
                }))

                strongSelf.present(alertController, animated: true, completion: nil)

            default:
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }

    private func acceptItem(at indexPath: IndexPath, completion: ((Bool) -> Swift.Void)? = nil) {
        signInView?.textField.text = nil

        let newIndexPath = IndexPath(item: itemCount, section: 0)
        UIView.performWithoutAnimation {
            addItem(at: newIndexPath, completion: { [weak self] _ in
                UIView.performWithoutAnimation {
                    self?.cleanUp(after: newIndexPath, completion: { [weak self] _ in
                        guard let itemCount = self?.itemCount else { return }
                        let newIndexPath = IndexPath(item: itemCount - 1, section: 0)
                        self?.signInView?.collectionView.selectItem(at: newIndexPath, animated: false, scrollPosition: .top)
                        UIView.performWithoutAnimation {
                            self?.cleanUp(after: newIndexPath, completion: completion)
                        }
                    })
                }
            })
        }
    }

    private func addItem(at indexPath: IndexPath, completion: ((Bool) -> Swift.Void)? = nil) {

        if itemCount == SignInViewController.maxItemCount, let activeIndexPath = activeIndexPath {
            signInView?.collectionView.deselectItem(at: activeIndexPath, animated: false)
            
            cleanUp(after: IndexPath(item: SignInViewController.maxItemCount, section: 0), completion: { [weak self] _ in
                guard let itemCount = self?.itemCount, itemCount < SignInViewController.maxItemCount else { return }
                self?.acceptItem(at: IndexPath(item: SignInViewController.maxItemCount, section: 0))
            })
            
            return
        }

        UIView.animate(withDuration: 0) {
            self.signInView?.collectionView.performBatchUpdates({
                self.signInView?.collectionView.insertItems(at: [indexPath])
                self.itemCount += 1
                self.enteredStrings.append("")
            }, completion: { finished in
                self.signInView?.layoutIfNeeded()
                completion?(finished)
            })
        }
    }

    private func cleanUp(after indexPath: IndexPath, completion: ((Bool) -> Swift.Void)? = nil) {

        UIView.animate(withDuration: 0) {
            self.signInView?.collectionView.performBatchUpdates({
                self.signInView?.collectionView.indexPathsForVisibleItems.forEach {

                    if $0 != indexPath, let string = self.enteredStrings.element(at: $0.item), string.isEmpty {
                        self.enteredStrings.remove(at: $0.item)
                        self.signInView?.collectionView.deleteItems(at: [$0])
                        self.itemCount -= 1
                    }
                }
            }, completion: { finished in
                self.signInView?.layoutIfNeeded()
                completion?(finished)
            })
        }
    }
    
    func showTextEditingOptions(for indexPath: IndexPath) {
        
        if let superview = signInView?.contentView, let sourceView = signInView?.collectionView.cellForItem(at: indexPath) {
            presentedViewController?.dismiss(animated: true)
            
            let textEditingOptionsViewController = TextEditingOptionsViewController(for: sourceView, in: superview)
            textEditingOptionsViewController.delegate = self
            present(textEditingOptionsViewController, animated: true)
        }
    }
}

extension SignInViewController: ActivityIndicating {
    var activityIndicator: UIActivityIndicatorView {
        return activityView
    }
}

extension SignInViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension SignInViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let activeIndexPath = activeIndexPath, indexPath == activeIndexPath else { return true }
        
        if let text = enteredStrings.element(at: indexPath.item), text.isEmpty {
            showTextEditingOptions(for: indexPath)
        } else {
            shouldDeselectWord = true
            acceptItem(at: indexPath, completion: { [weak self] _ in
                guard let indexPath = self?.activeIndexPath else { return }
                self?.cleanUp(after: indexPath)
            })
        }
        
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if let cell = activeCell, !shouldDeselectWord {
            signInView?.textField.text = cell.text
            cleanUp(after: indexPath)
        } else if itemCount == SignInViewController.maxItemCount, let activeIndexPath = activeIndexPath {
            signInView?.collectionView.deselectItem(at: activeIndexPath, animated: false)
        }

        shouldDeselectWord = false
    }
}

extension SignInViewController: TextEditingOptionsViewControllerDelegate {
    
    func pasteSelected(from textEditingOptionsViewController: TextEditingOptionsViewController) {
        guard let pasted = stringFromClipboard() else { return }
        
        userDidPastePassphrase = true
        
        enteredStrings = pasted.components(separatedBy: " ").map { String($0.prefix(PasswordValidator.shared.maxCharacterCount)) }
        if enteredStrings.count > SignInViewController.maxItemCount {
            enteredStrings.removeSubrange(SignInViewController.maxItemCount...)
        }
        itemCount = enteredStrings.count
        
        signInView?.collectionView.reloadData()
        signInView?.collectionView.collectionViewLayout.invalidateLayout()
        signInView?.layoutIfNeeded()
        
        userDidPastePassphrase = false
        
        if itemCount < SignInViewController.maxItemCount {
            acceptItem(at: IndexPath(item: itemCount - 1, section: 0))
        }
    }
}

extension SignInViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SignInCell.reuseIdentifier, for: indexPath)

        if let cell = cell as? SignInCell {
            let text = enteredStrings[indexPath.item]

            if !userDidPastePassphrase {
                cell.setText(text, isFirstAndOnly: itemCount == 1)
                return cell
            }

            let comparison = PasswordValidator.shared.validateWord(for: text)

            if let match = comparison.match {
                cell.setText(text, with: match)
            } else {
                cell.setText(text, isFirstAndOnly: itemCount == 1)
            }

            cell.isActive = false

            collectionView.deselectItem(at: indexPath, animated: false)
            signInView?.textField.text = nil
        }

        return cell
    }
}

extension SignInViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let indexPath = activeIndexPath else { return false }
        guard let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else { return false }
        
        presentedViewController?.dismiss(animated: true)

        if string == " " || string == "\n" {
            acceptItem(at: indexPath)

            return false
        }

        enteredStrings[indexPath.item] = text
        
        let comparison = PasswordValidator.shared.validateWord(for: text)
        
        if let match = comparison.match {
            activeCell?.setText(text, with: match)
            
            if comparison.isSingleOccurrence, match == text {
                acceptItem(at: indexPath)
                
                return false
            }
        } else {
            activeCell?.setText(text, isFirstAndOnly: itemCount == 1)
        }
        
        signInView?.collectionView.collectionViewLayout.invalidateLayout()
        signInView?.layoutIfNeeded()
        
        if text.count >= PasswordValidator.shared.maxCharacterCount {
            acceptItem(at: indexPath)
            
            return false
        }
        
        return true
    }
}

extension SignInViewController: TextFieldDeleteDelegate {

    func backspacedOnEmptyField() {
        guard let indexPath = activeIndexPath, indexPath.item != 0 else { return }

        let newIndexPath = IndexPath(item: indexPath.item - 1, section: 0)
        signInView?.collectionView.selectItem(at: newIndexPath, animated: false, scrollPosition: .top)

        if let cell = activeCell {
            signInView?.textField.text = cell.text
        }

        cleanUp(after: newIndexPath)
    }
}

extension SignInViewController: ClipboardCopying { /* mix-in */ }
