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

@testable import Toshi
import XCTest

class MessageParsingTests: XCTestCase {
    
    private let otherUserID = "SomeUser"
    private let nonZeroTimeStamp: UInt64 = 5
    private let nonZeroDeviceID: UInt32 = 3
    
    private lazy var normalThread: TSThread = {
        return TSContactThread(uniqueId: self.otherUserID)!
    }()
    
    private lazy var textMessageBody: String = {
        return "\(SofaType.message.rawValue){\"body\":\"o hai\"}"
    }()
    
    private lazy var paymentMessageBody: String = {
        return "\(SofaType.payment.rawValue){\"value\":\"0x17ac784453a3d2\"}"
    }()
    
    private lazy var paymentRequestMessageBody: String = {
        return "\(SofaType.paymentRequest.rawValue){\"value\":\"0x17ac784453a3d2\"}"
    }()
    
    // MARK: - Single User Threads
    
    // MARK: Outgoing

    func testHandlingInvalidKeyMessage() {
        let interactor = ChatInteractor(output: nil, thread: normalThread)
        
        let message = TSInvalidIdentityKeySendingErrorMessage(timestamp: nonZeroTimeStamp,
                                                              in: normalThread,
                                                              failedMessageType: .missingKeyId,
                                                              recipientId: otherUserID)
        
        let parsed = interactor.handleSignalMessage(message)
        
        XCTAssertNil(parsed.fiatValueString)
        XCTAssertNil(parsed.ethereumValueString)
        XCTAssertNil(parsed.attachment)
        XCTAssertNil(parsed.image)
        XCTAssertNil(parsed.title)
        XCTAssertNil(parsed.subtitle)
        XCTAssertNil(parsed.attributedTitle)
        XCTAssertNil(parsed.attributedSubtitle)
        XCTAssertNil(parsed.sofaWrapper)
        XCTAssertNil(parsed.text)
        XCTAssertNil(parsed.attributedText)

        XCTAssertFalse(parsed.isOutgoing)
        XCTAssertFalse(parsed.isActionable)
        XCTAssertFalse(parsed.isDisplayable)
        
        XCTAssertEqual(parsed.messageType, "Text")
        XCTAssertEqual(parsed.signalMessage, message)
        XCTAssertEqual(parsed.deliveryStatus, .attemptingOut)
    }
    
    func testParsingOutgoingMessage() {
        let interactor = ChatInteractor(output: nil, thread: normalThread)
        
        let message = TSOutgoingMessage(timestamp: nonZeroTimeStamp,
                                        in: normalThread,
                                        messageBody: textMessageBody)
        
        let parsed = interactor.handleSignalMessage(message)
        
        XCTAssertNil(parsed.fiatValueString)
        XCTAssertNil(parsed.ethereumValueString)
        XCTAssertNil(parsed.attachment)
        XCTAssertNil(parsed.image)
        XCTAssertNil(parsed.title)
        XCTAssertNil(parsed.subtitle)
        XCTAssertNil(parsed.attributedTitle)
        XCTAssertNil(parsed.attributedSubtitle)
        XCTAssertNil(parsed.attributedText)
        
        XCTAssertTrue(parsed.isOutgoing)
        XCTAssertTrue(parsed.isDisplayable)

        XCTAssertFalse(parsed.isActionable)
        
        XCTAssertEqual(parsed.messageType, "Text")
        XCTAssertEqual(parsed.signalMessage, message)
        XCTAssertEqual(parsed.text, "o hai")
        XCTAssertEqual(parsed.sofaWrapper?.type, .message)
        XCTAssertEqual(parsed.deliveryStatus, .attemptingOut)
    }
    
    func testParsingOutgoingMessageWithAttachments() {
        let interactor = ChatInteractor(output: nil, thread: normalThread)
        
        let message = TSOutgoingMessage(timestamp: nonZeroTimeStamp,
                                        in: normalThread,
                                        messageBody: textMessageBody,
                                        attachmentIds: NSMutableArray(array: ["One", "Two"]))
        
        let parsed = interactor.handleSignalMessage(message)

        XCTAssertNil(parsed.fiatValueString)
        XCTAssertNil(parsed.ethereumValueString)
        XCTAssertNil(parsed.attachment) // This should be nil since there arent' actually attachments saved
        XCTAssertNil(parsed.image)
        XCTAssertNil(parsed.title)
        XCTAssertNil(parsed.subtitle)
        XCTAssertNil(parsed.attributedTitle)
        XCTAssertNil(parsed.attributedSubtitle)
        XCTAssertNil(parsed.attributedText)
        
        XCTAssertTrue(parsed.isOutgoing)
        XCTAssertTrue(parsed.isDisplayable)
        
        XCTAssertFalse(parsed.isActionable)
        
        XCTAssertEqual(parsed.messageType, "Image")
        XCTAssertEqual(parsed.signalMessage, message)
        XCTAssertEqual(parsed.text, "o hai")
        XCTAssertEqual(parsed.sofaWrapper?.type, .message)
        XCTAssertEqual(parsed.deliveryStatus, .attemptingOut)
    }
    
    func testParsingOutgoingPayment() {
        let interactor = ChatInteractor(output: nil, thread: normalThread)
        
        let message = TSOutgoingMessage(timestamp: nonZeroTimeStamp,
                                        in: normalThread,
                                        messageBody: paymentMessageBody)
        
        let parsed = interactor.handleSignalMessage(message)
        
        // These are not calculated until display due to exchange rates
        XCTAssertNil(parsed.fiatValueString)
        XCTAssertNil(parsed.ethereumValueString)
        
        XCTAssertNil(parsed.attachment)
        XCTAssertNil(parsed.image)
        XCTAssertNil(parsed.text)
        XCTAssertNil(parsed.attributedText)
        
        XCTAssertTrue(parsed.isOutgoing)
        XCTAssertTrue(parsed.isDisplayable)
        
        XCTAssertFalse(parsed.isActionable)
        
        // TODO: Update when this bug is fixed: https://toshiapp.atlassian.net/browse/IOS-456
        XCTAssertEqual(parsed.messageType, "Actionable")
        XCTAssertEqual(parsed.signalMessage, message)
        XCTAssertEqual(parsed.title, "Payment sent")
        XCTAssertEqual(parsed.attributedTitle?.string, "Payment sent")
        XCTAssertEqual(parsed.sofaWrapper?.type, .payment)
        XCTAssertEqual(parsed.deliveryStatus, .attemptingOut)
        
        guard let payment = parsed.sofaWrapper as? SofaPayment else {
            XCTFail("This should be a payment")
            
            return
        }
        
        // We don't know what this will be because conversion rates fluctuate, but it should be *something*
        XCTAssertFalse(payment.fiatValueString.isEmpty,
                       "Payment Fiat value string has no content")
        
        let ethereumValueString = EthereumConverter.ethereumValueString(forWei: payment.value)
        XCTAssertEqual(ethereumValueString, "0.0067 ETH",
                       "Ethereum value string for static hex code has changed")
        XCTAssertTrue(parsed.subtitle?.contains(ethereumValueString) ?? false,
                      "Subtitle \"\(parsed.subtitle ?? "(null)")\" does not contain \"\(ethereumValueString)\"")
        XCTAssertTrue(parsed.subtitle?.contains(payment.fiatValueString) ?? false,
                      "Subtitle \"\(parsed.subtitle ?? "(null)")\" does not contain \"\(payment.fiatValueString)\"")
        XCTAssertTrue(parsed.attributedSubtitle?.string.contains(ethereumValueString) ?? false,
                      "Attributed subtitle's underlying string does not contain \"\(ethereumValueString)\"")
        XCTAssertTrue(parsed.attributedSubtitle?.string.contains(payment.fiatValueString) ?? false,
                      "Attributed subtitle's underlying string does not contain \"\(payment.fiatValueString)\"")

    }
    
    func testParsingOutgoingPaymentRequest() {
        let interactor = ChatInteractor(output: nil, thread: normalThread)
        
        let message = TSOutgoingMessage(timestamp: nonZeroTimeStamp,
                                        in: normalThread,
                                        messageBody: paymentRequestMessageBody)
        
        // Payment requests should always process commands
        let parsed = interactor.handleSignalMessage(message, shouldProcessCommands: true)
        
        // These are not calculated until display due to exchange rates
        XCTAssertNil(parsed.fiatValueString)
        XCTAssertNil(parsed.ethereumValueString)
        
        XCTAssertNil(parsed.attachment)
        XCTAssertNil(parsed.image)
        XCTAssertNil(parsed.attributedText)
        XCTAssertNil(parsed.title)
        XCTAssertNil(parsed.attributedTitle)
        
        XCTAssertTrue(parsed.isOutgoing)
        
        XCTAssertFalse(parsed.isDisplayable)
        XCTAssertFalse(parsed.isActionable)

        XCTAssertEqual(parsed.messageType, "Text")
        XCTAssertEqual(parsed.text, "")
        XCTAssertEqual(parsed.signalMessage, message)
        XCTAssertEqual(parsed.sofaWrapper?.type, .paymentRequest)
        XCTAssertEqual(parsed.deliveryStatus, .attemptingOut)
        
        guard let paymentRequest = parsed.sofaWrapper as? SofaPaymentRequest else {
            XCTFail("This should be a payment request")
            
            return
        }
        
        let ethereumValueString = EthereumConverter.ethereumValueString(forWei: paymentRequest.value)
        XCTAssertEqual(ethereumValueString, "0.0067 ETH",
                       "Ethereum value string for static hex code has changed")
    }
    
    // MARK: Incoming
    
    func testParsingIncomingPayment() {
        let interactor = ChatInteractor(output: nil, thread: normalThread)
        
        let message = TSIncomingMessage(timestamp: nonZeroTimeStamp,
                                        in: normalThread,
                                        authorId: otherUserID,
                                        sourceDeviceId: nonZeroDeviceID,
                                        messageBody: paymentMessageBody)
        
        let parsed = interactor.handleSignalMessage(message)
        
        XCTAssertNil(parsed.fiatValueString)
        XCTAssertNil(parsed.ethereumValueString)
        
        XCTAssertNil(parsed.attachment)
        XCTAssertNil(parsed.image)
        XCTAssertNil(parsed.text)
        XCTAssertNil(parsed.attributedText)
        
        XCTAssertFalse(parsed.isOutgoing)
        
        XCTAssertFalse(parsed.isActionable)

        XCTAssertTrue(parsed.isDisplayable)
        
        // TODO: Update when this bug is fixed: https://toshiapp.atlassian.net/browse/IOS-456
        XCTAssertEqual(parsed.messageType, "Actionable")
        XCTAssertEqual(parsed.signalMessage, message)
        XCTAssertEqual(parsed.title, "Payment received")
        XCTAssertEqual(parsed.attributedTitle?.string, "Payment received")
        XCTAssertEqual(parsed.sofaWrapper?.type, .payment)
        XCTAssertEqual(parsed.deliveryStatus, .attemptingOut)
        
        guard let payment = parsed.sofaWrapper as? SofaPayment else {
            XCTFail("This should be a payment")
            
            return
        }
        
        XCTAssertEqual(payment.status, .unconfirmed)
        
        // We don't know what this will be because conversion rates fluctuate, but it should be *something*
        XCTAssertFalse(payment.fiatValueString.isEmpty,
                       "Payment Fiat value string has no content")
        
        let ethereumValueString = EthereumConverter.ethereumValueString(forWei: payment.value)
        XCTAssertEqual(ethereumValueString, "0.0067 ETH",
                       "Ethereum value string for static hex code has changed")
        XCTAssertTrue(parsed.subtitle?.contains(ethereumValueString) ?? false,
                      "Subtitle \"\(parsed.subtitle ?? "(null)")\" does not contain \"\(ethereumValueString)\"")
        XCTAssertTrue(parsed.subtitle?.contains(payment.fiatValueString) ?? false,
                      "Subtitle \"\(parsed.subtitle ?? "(null)")\" does not contain \"\(payment.fiatValueString)\"")
        XCTAssertTrue(parsed.attributedSubtitle?.string.contains(ethereumValueString) ?? false,
                      "Attributed subtitle's underlying string does not contain \"\(ethereumValueString)\"")
        XCTAssertTrue(parsed.attributedSubtitle?.string.contains(payment.fiatValueString) ?? false,
                      "Attributed subtitle's underlying string does not contain \"\(payment.fiatValueString)\"")
    }
    
    func testIncomingPaymentRequest() {
        let interactor = ChatInteractor(output: nil, thread: normalThread)
        
        let message = TSIncomingMessage(timestamp: nonZeroTimeStamp,
                                        in: normalThread,
                                        authorId: otherUserID,
                                        sourceDeviceId: nonZeroDeviceID,
                                        messageBody: paymentRequestMessageBody)
        
        // Payment requests should always process commands
        let parsed = interactor.handleSignalMessage(message, shouldProcessCommands: true)
        
        XCTAssertNil(parsed.fiatValueString)
        XCTAssertNil(parsed.ethereumValueString)
        
        XCTAssertNil(parsed.attachment)
        XCTAssertNil(parsed.image)
        XCTAssertNil(parsed.attributedText)
        
        XCTAssertFalse(parsed.isOutgoing)
        XCTAssertFalse(parsed.isDisplayable)

        XCTAssertTrue(parsed.isActionable)
        
        XCTAssertEqual(parsed.messageType, "Actionable")
        XCTAssertEqual(parsed.text, "")
        XCTAssertEqual(parsed.signalMessage, message)
        XCTAssertEqual(parsed.title, "Payment request")
        XCTAssertEqual(parsed.attributedTitle?.string, "Payment request")
        XCTAssertEqual(parsed.sofaWrapper?.type, .paymentRequest)
        XCTAssertEqual(parsed.deliveryStatus, .attemptingOut)
        
        guard let paymentRequest = parsed.sofaWrapper as? SofaPaymentRequest else {
            XCTFail("This should be a payment request")
            
            return
        }
        
        let ethereumValueString = EthereumConverter.ethereumValueString(forWei: paymentRequest.value)
        
        // We don't know what this will be because conversion rates fluctuate, but it should be *something*
        XCTAssertFalse(paymentRequest.fiatValueString.isEmpty,
                       "Payment Fiat value string has no content")
        
        XCTAssertEqual(ethereumValueString, "0.0067 ETH",
                       "Ethereum value string for static hex code has changed")
        XCTAssertTrue(parsed.subtitle?.contains(ethereumValueString) ?? false,
                      "Subtitle \"\(parsed.subtitle ?? "(null)")\" does not contain \"\(ethereumValueString)\"")
        XCTAssertTrue(parsed.subtitle?.contains(paymentRequest.fiatValueString) ?? false,
                      "Subtitle \"\(parsed.subtitle ?? "(null)")\" does not contain \"\(paymentRequest.fiatValueString)\"")
        XCTAssertTrue(parsed.attributedSubtitle?.string.contains(ethereumValueString) ?? false,
                      "Attributed subtitle's underlying string does not contain \"\(ethereumValueString)\"")
        XCTAssertTrue(parsed.attributedSubtitle?.string.contains(paymentRequest.fiatValueString) ?? false,
                      "Attributed subtitle's underlying string does not contain \"\(paymentRequest.fiatValueString)\"")
        
    }
}
