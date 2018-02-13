import Foundation
import UIKit
import TinyConstraints
import SweetUIKit

protocol TextEditingOptionsViewControllerDelegate: class {
    func pasteSelected(from textEditingOptionsViewController: TextEditingOptionsViewController)
}

final class TextEditingOptionsViewController: UIViewController {
    
    weak var delegate: TextEditingOptionsViewControllerDelegate?
    
    private lazy var segmentedControl: UISegmentedControl = {
        let editingOptions = [Localized("text_editing_options_paste")]
        let attributes: [NSAttributedStringKey: Any] = [.font: Theme.light(size: 14), .foregroundColor: Theme.lightTextColor]
        
        let view = UISegmentedControl(items: editingOptions)
        view.setTitleTextAttributes(attributes, for: .normal)
        view.tintColor = .clear
        view.addTarget(self, action: #selector(valueChanged(for:)), for: .valueChanged)
        
        return view
    }()
    
    convenience init(for sourceView: UIView, in superview: UIView) {
        self.init()
        
        modalPresentationStyle = .popover
        preferredContentSize = CGSize(width: 70, height: 35)
        
        if let presentationController = popoverPresentationController {
            presentationController.delegate = self
            presentationController.permittedArrowDirections = .down
            presentationController.backgroundColor = Theme.darkTextColor
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
        
        view.addSubview(segmentedControl)
        segmentedControl.edgesToSuperview()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.superview?.superview?.bounce()
    }
    
    @objc func valueChanged(for segmentedControl: UISegmentedControl) {
        segmentedControl.selectedSegmentIndex = -1
        
        dismiss(animated: true) {
            self.delegate?.pasteSelected(from: self)
        }
    }
}

extension TextEditingOptionsViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
