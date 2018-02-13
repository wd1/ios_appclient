import Foundation
import UIKit
import TinyConstraints
import SweetUIKit

protocol ChatMenuTableViewControllerDelegate: class {
    func didSelectButton(_ button: SofaMessage.Button, at indexPath: IndexPath)
}

final class ChatMenuTableViewController: UITableViewController {
    
    weak var delegate: ChatMenuTableViewControllerDelegate?
    private let rowHeight: CGFloat = 46
    
    var buttons: [SofaMessage.Button]? = [] {
        didSet {
            (viewIfLoaded as? UITableView)?.reloadData()
            preferredContentSize = CGSize(width: 260, height: CGFloat(buttons?.count ?? 0) * rowHeight)
            preferredContentSizeDidChange(forChildContentContainer: self)
        }
    }
    
    convenience init(for sourceView: UIView, in superview: UIView) {
        self.init()
        
        modalPresentationStyle = .popover
        preferredContentSize = CGSize(width: 250, height: 200)
        
        if let presentationController = popoverPresentationController {
            presentationController.delegate = self
            presentationController.permittedArrowDirections = .down
            presentationController.backgroundColor = Theme.viewBackgroundColor
            presentationController.canOverlapSourceViewRect = true
            presentationController.sourceView = sourceView
            presentationController.sourceRect = sourceFrame(for: sourceView, in: superview)
        }
    }
    
    func sourceFrame(for sourceView: UIView, in superview: UIView) -> CGRect {
        var sourceFrame = superview.convert(sourceView.frame, from: superview)
        
        if let cell = sourceView as? SignInCell {
            let origin = cell.caretView.convert(cell.caretView.frame.origin, to: cell)
            let sourceWidth = origin.x + 14
            sourceFrame.size.width = sourceFrame.origin.x <= 15 ? max(70, sourceWidth) : sourceWidth
        }
        
        sourceFrame.origin = .zero
        return sourceFrame
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = nil
        view.isOpaque = false
        
        tableView.separatorStyle = .none
        tableView.register(ChatMenuTableViewCell.self, forCellReuseIdentifier: ChatMenuTableViewCell.reuseIdentifier)
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let superview = view.superview?.superview {
            superview.alpha = 0
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let superview = view.superview?.superview {
            
            superview.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
            superview.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            
            UIView.animate(withDuration: 0.2, animations: {
                superview.alpha = 1
            })
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
                superview.transform = .identity
            }, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let buttons = buttons else { return }
        dismiss(animated: true) {
            self.delegate?.didSelectButton(buttons[indexPath.row], at: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buttons?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatMenuTableViewCell.reuseIdentifier, for: indexPath)
        
        if let cell = cell as? ChatMenuTableViewCell, let buttons = buttons, let button = buttons.element(at: indexPath.row), let text = button.label {
            cell.textLabel?.attributedText = NSMutableAttributedString(string: text, attributes: [.foregroundColor: Theme.tintColor, .font: Theme.preferredRegular()])
            cell.bottomDivider.isHidden = indexPath.row == buttons.count - 1
        }
        
        return cell
    }
}

extension ChatMenuTableViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
