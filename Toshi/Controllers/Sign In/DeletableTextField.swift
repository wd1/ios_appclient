import Foundation
import UIKit
import TinyConstraints

protocol TextFieldDeleteDelegate: class {
    func backspacedOnEmptyField()
}

final class DeletableTextField: UITextField {

    weak var deleteDelegate: TextFieldDeleteDelegate?

    override func deleteBackward() {
        if let text = text, !text.isEmpty {
            super.deleteBackward()
            return
        }

        deleteDelegate?.backspacedOnEmptyField()
    }
}
