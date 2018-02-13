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

import Foundation
import UIKit

class Message: NSObject {

    var fiatValueString: String?
    var ethereumValueString: String?

    var messageId: String = UUID().uuidString
    var messageType: String = "Text"

    let signalMessage: TSMessage

    var attributedTitle: NSAttributedString?
    var attributedSubtitle: NSAttributedString?

    var attachment: TSAttachment? {
        if signalMessage.hasAttachments(), let attachmentId = (self.signalMessage.attachmentIds as? [String])?.first, let attachment = TSAttachment.fetch(uniqueId: attachmentId) {

            return attachment
        }

        return nil
    }

    private lazy var attachmentsCache: NSCache<NSString, UIImage> = {
        NSCache<NSString, UIImage>()
    }()

    private func streamImage(for stream: TSAttachmentStream) -> UIImage? {
        var image: UIImage?

        if let cachedImage = self.attachmentsCache.object(forKey: self.uniqueIdentifier() as NSString) {
            image = cachedImage
        } else {
            if let streamImage = stream.image() {
                attachmentsCache.setObject(streamImage, forKey: uniqueIdentifier() as NSString)
                image = streamImage
            }
        }

        return image
    }

    var image: UIImage? {
        if attachment is TSAttachmentPointer {
            return #imageLiteral(resourceName: "placeholder")
        } else if let stream = attachment as? TSAttachmentStream {

            guard let image = self.streamImage(for: stream) else { return #imageLiteral(resourceName: "placeholder") }
            // TODO: add play button if video
            return image
        }

        return nil
    }

    var title: String? {
        set {
            if let string = newValue {
                attributedTitle = NSAttributedString(string: string, attributes: [.font: Theme.semibold(size: 15), .foregroundColor: Theme.incomingMessageTextColor])
            } else {
                attributedTitle = nil
            }
        }
        get {
            return attributedTitle?.string
        }
    }

    var subtitle: String? {
        set {
            if let string = newValue {
                attributedSubtitle = NSAttributedString(string: string, attributes: [.font: Theme.preferredRegularSmall(), .foregroundColor: Theme.incomingMessageTextColor])
            } else {
                attributedSubtitle = nil
            }
        }
        get {
            return attributedSubtitle?.string
        }
    }

    var date: Date

    var isOutgoing: Bool = true
    var isActionable: Bool

    var deliveryStatus: TSOutgoingMessageState {
        return (self.signalMessage as? TSOutgoingMessage)?.messageState ?? .attemptingOut
    }

    var sofaWrapper: SofaWrapper?

    var isDisplayable: Bool {
        // we are displayable even if there's no sofa content but we have attachments
        guard self.attachment == nil else { return true }

        // we don't display them if sofa wrapper is nil
        guard let sofaWrapper = self.sofaWrapper else { return false }

        // if we have no attachments and still have a wrapper, if it's a .message but empty
        // it's a `wake up` message, so we don't display them either, if it is payment message and destination address is valid, if it is a status message having attributed text.
        if let message = sofaWrapper as? SofaMessage {
            guard !message.body.isEmpty else { return false }
        } else if let paymentRequest = sofaWrapper as? SofaPaymentRequest {
            guard EthereumAddress.validate(paymentRequest.destinationAddress) else { return false }
        } else if let status = sofaWrapper as? SofaStatus {
            guard status.attributedText != nil else { return false }
        }

        let typesThatShouldBeDisplayed: [SofaType] = [.message, .paymentRequest, .payment, .command, .status]
        return typesThatShouldBeDisplayed.contains(sofaWrapper.type)
    }

    var text: String? {
        guard let sofaWrapper = self.sofaWrapper else { return nil }
        switch sofaWrapper.type {
        case .message:
            return (sofaWrapper as? SofaMessage)?.body
        case .paymentRequest:
            return (sofaWrapper as? SofaPaymentRequest)?.body
        case .payment:
            return nil
        case .command:
            return (sofaWrapper as? SofaCommand)?.body
        default:
            return sofaWrapper.content
        }
    }

    var attributedText: NSAttributedString? {
        guard let sofaWrapper = self.sofaWrapper, sofaWrapper.type == .status else { return nil }

        return (sofaWrapper as? SofaStatus)?.attributedText
    }

    func uniqueIdentifier() -> String {
        return self.messageId
    }

    func type() -> String {
        return self.messageType
    }

    init(sofaWrapper: SofaWrapper?, signalMessage: TSMessage, date: Date? = nil, isOutgoing: Bool = true, shouldProcess: Bool = false) {
        self.sofaWrapper = sofaWrapper
        self.isOutgoing = isOutgoing
        self.signalMessage = signalMessage
        self.date = date ?? Date()
        self.isActionable = shouldProcess && !isOutgoing && (sofaWrapper?.type == .paymentRequest)

        super.init()
    }
}
