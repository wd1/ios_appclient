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
import HPGrowingTextView
import SweetUIKit

protocol ChatInputTextPanelDelegate: class {
    func inputTextPanel(_ inputTextPanel: ChatInputTextPanel, requestSendText text: String)
    func inputTextPanelRequestSendAttachment(_ inputTextPanel: ChatInputTextPanel)
    func inputTextPanelDidChangeHeight(_ height: CGFloat)
}

class ChatInputTextPanel: UIView {
    
    weak var delegate: ChatInputTextPanelDelegate?

    static let defaultHeight: CGFloat = 44

    private let inputContainerInsets = UIEdgeInsets(top: 1, left: 41, bottom: 7, right: 0)
    private let maximumInputContainerHeight: CGFloat = 175
    private var inputContainerHeight: CGFloat = ChatInputTextPanel.defaultHeight {
        didSet {
            if self.inputContainerHeight != oldValue {
                delegate?.inputTextPanelDidChangeHeight(self.inputContainerHeight)
            }
        }
    }

    private func inputContainerHeight(for textViewHeight: CGFloat) -> CGFloat {
        return min(maximumInputContainerHeight, max(ChatInputTextPanel.defaultHeight, textViewHeight + inputContainerInsets.top + inputContainerInsets.bottom))
    }

    lazy var inputContainer = UIView(withAutoLayout: true)

    lazy var inputField: HPGrowingTextView = {
        let view = HPGrowingTextView(withAutoLayout: true)
        view.backgroundColor = Theme.chatInputFieldBackgroundColor
        view.clipsToBounds = true
        view.layer.cornerRadius = (ChatInputTextPanel.defaultHeight - (self.inputContainerInsets.top + self.inputContainerInsets.bottom)) / 2
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = .lineHeight
        view.delegate = self
        view.placeholder = Localized("chat_input_empty_placeholder")
        view.contentInset = UIEdgeInsets(top: 0, left: 11, bottom: 0, right: 0)
        view.font = UIFont.systemFont(ofSize: 16)
        view.internalTextView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 5)
        view.internalTextView.scrollIndicatorInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 5)

        return view
    }()

    private lazy var attachButton: UIButton = {
        let view = UIButton(withAutoLayout: true)
        view.setImage(#imageLiteral(resourceName: "TGAttachButton").withRenderingMode(.alwaysTemplate), for: .normal)
        view.tintColor = Theme.tintColor
        view.contentMode = .center
        view.addTarget(self, action: #selector(attach(_:)), for: .touchUpInside)

        return view
    }()

    private lazy var sendButton: RoundIconButton = {
        let view = RoundIconButton(imageName: "send-button", circleDiameter: 27)
        view.isEnabled = false
        view.addTarget(self, action: #selector(send(_:)), for: .touchUpInside)

        return view
    }()

    var text: String? {
        get {
            return inputField.text
        } set {
            inputField.text = newValue ?? ""
        }
    }

    private lazy var sendButtonWidth: NSLayoutConstraint = {
        self.sendButton.width(0)
    }()

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(inputContainer)
        addSubview(attachButton)
        addSubview(inputField)
        addSubview(sendButton)

        NSLayoutConstraint.activate([
            self.attachButton.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.attachButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.attachButton.rightAnchor.constraint(equalTo: self.inputField.leftAnchor),
            self.attachButton.widthAnchor.constraint(equalToConstant: ChatInputTextPanel.defaultHeight),
            self.attachButton.heightAnchor.constraint(equalToConstant: ChatInputTextPanel.defaultHeight),

            self.inputContainer.topAnchor.constraint(equalTo: self.topAnchor),
            self.inputContainer.leftAnchor.constraint(equalTo: self.leftAnchor, constant: -1),
            self.inputContainer.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.inputContainer.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 1),

            self.inputField.topAnchor.constraint(equalTo: self.topAnchor, constant: self.inputContainerInsets.top),
            self.inputField.leftAnchor.constraint(equalTo: self.attachButton.rightAnchor),
            self.inputField.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -self.inputContainerInsets.bottom)
        ])

        sendButton.leftToRight(of: inputField)
        sendButton.bottom(to: self, offset: -3)
        sendButton.right(to: self)
        sendButton.height(44)
        sendButtonWidth.isActive = true
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        if self.point(inside: point, with: event) {

            for subview in subviews.reversed() {
                let point = subview.convert(point, from: self)

                if let hitTestView = subview.hitTest(point, with: event) {
                    return hitTestView
                }
            }

            return nil
        }

        return nil
    }

    @objc func attach(_: ActionButton) {
        delegate?.inputTextPanelRequestSendAttachment(self)
    }

    @objc func send(_: ActionButton) {
        // Resign and become first responder to accept auto-correct suggestions
        let temp = UITextField()
        temp.isHidden = true
        superview?.addSubview(temp)
        temp.becomeFirstResponder()
        inputField.internalTextView.becomeFirstResponder()
        temp.removeFromSuperview()

        guard let text = self.inputField.text, !text.isEmpty else { return }

        let string = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !string.isEmpty {
            delegate?.inputTextPanel(self, requestSendText: string)
        }

        self.text = nil
        sendButton.isEnabled = false
    }
}

extension ChatInputTextPanel: HPGrowingTextViewDelegate {

    func growingTextView(_ textView: HPGrowingTextView!, willChangeHeight _: Float) {

        self.layoutIfNeeded()

        self.inputContainerHeight = self.inputContainerHeight(for: textView.frame.height)

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 5, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
            self.layoutIfNeeded()
        }, completion: nil)
    }

    func growingTextViewDidChange(_ textView: HPGrowingTextView!) {
        self.layoutIfNeeded()

        let hasText = inputField.internalTextView.hasText

        self.sendButtonWidth.constant = hasText ? 44 : 10

        self.inputContainerHeight = self.inputContainerHeight(for: textView.frame.height)

        UIView.animate(withDuration: hasText ? 0.4 : 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 5, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
            self.layoutIfNeeded()
            self.sendButton.isEnabled = hasText
        }, completion: nil)
    }
}
