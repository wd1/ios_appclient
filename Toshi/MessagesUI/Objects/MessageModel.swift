import Foundation
import UIKit

enum MessageType {
    case simple
    case image
    case paymentRequest
    case payment
    case status
}

struct MessageModel {
    private let message: Message

    var type: MessageType
    var title: String?
    var subtitle: String?
    let text: String?
    let attributedText: NSAttributedString?
    let isOutgoing: Bool

    var identifier: String {
        return message.uniqueIdentifier()
    }

    var image: UIImage? {
        if message.image != nil {
            return message.image
        } else {
            return nil
        }
    }

    var isActionable: Bool
    var signalMessage: TSMessage?
    var sofaWrapper: SofaWrapper?

    var fiatValueString: String?
    var ethereumValueString: String?

    init(message: Message) {
        self.message = message

        isOutgoing = message.isOutgoing

        if let title = message.title, !title.isEmpty {
            self.title = title
        } else {
            title = nil
        }

        fiatValueString = nil
        ethereumValueString = nil

        subtitle = message.subtitle
        text = message.text
        attributedText = message.attributedText

        signalMessage = message.signalMessage
        sofaWrapper = message.sofaWrapper

        if message.sofaWrapper?.type == .paymentRequest {
            type = .paymentRequest
            isActionable = true

            fiatValueString = message.fiatValueString
            ethereumValueString = message.ethereumValueString

            if let fiatValueString = message.fiatValueString {
                title = "Request for \(fiatValueString)"
            }
            subtitle = message.ethereumValueString

        } else if message.sofaWrapper?.type == .payment {
            type = .payment
            isActionable = false

            fiatValueString = message.fiatValueString
            ethereumValueString = message.ethereumValueString

            if let fiatValueString = message.fiatValueString {
                title = "Payment for \(fiatValueString)"
            }
            subtitle = message.ethereumValueString

        } else if message.sofaWrapper?.type == .status {
            type = .status
            isActionable = true
        } else if message.image != nil {
            type = .image
            isActionable = false
        } else {
            type = .simple
            isActionable = false
        }
    }
}
