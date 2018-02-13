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

protocol ChatInteractorOutput: class {
    func didCatchError(_ message: String)

    func didFinishRequest()
}

final class ChatInteractor: NSObject {

    private weak var output: ChatInteractorOutput?
    private(set) var thread: TSThread

    init(output: ChatInteractorOutput?, thread: TSThread) {
        self.output = output
        self.thread = thread

        self.messageSender = SessionManager.shared.messageSender
    }

    private var etherAPIClient: EthereumAPIClient {
        return EthereumAPIClient.shared
    }

    private var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    private var messageSender: MessageSender?

    // MARK: - Sending
    
    func sendMessage(sofaWrapper: SofaWrapper, date: Date = Date(), completion: @escaping ((Bool) -> Void) = { Bool in }) {
        let timestamp = NSDate.ows_millisecondTimeStamp()

        sofaWrapper.removeFiatValueString()
        let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: self.thread, messageBody: sofaWrapper.content)

        self.send(outgoingMessage, completion: completion)
    }

    func send(_ signalMessage: TSOutgoingMessage, completion: @escaping ((Bool) -> Void) = { Bool in }) {
        DispatchQueue.main.async {
            self.messageSender?.send(signalMessage, success: {
                completion(true)
                DLog("message sent")
            }, failure: { [weak self] error in
                completion(false)
                DLog("\(error)")
                self?.logSendErrorIfRecipientUnregistered(error: error)
            })
        }
    }

    func send(image: UIImage, in message: TSOutgoingMessage? = nil, completion: ((Bool) -> Void)? = nil) {
        guard let imageData = UIImagePNGRepresentation(image) else { return }

        let wrapper = SofaMessage(body: "")
        let timestamp = NSDate.ows_millisecondsSince1970(for: Date())
        let outgoingMessage = message ?? TSOutgoingMessage(timestamp: timestamp, in: thread, messageBody: wrapper.content)

        guard let datasource = DataSourceValue.dataSource(with: imageData, fileExtension: "png") else { return }

        messageSender?.sendAttachmentData(datasource, contentType: "image/jpeg", sourceFilename: "image.jpeg", in: outgoingMessage, success: {
            DLog("Success")
            DispatchQueue.main.async {
                completion?(true)
            }
        }, failure: { [weak self] error in
            DLog("Failure: \(error)")
            self?.logSendErrorIfRecipientUnregistered(error: error)
            DispatchQueue.main.async {
                completion?(false)
            }
        })
    }

    func sendVideo(with url: URL) {
        guard let videoData = try? Data(contentsOf: url) else { return }

        let wrapper = SofaMessage(body: "")
        let timestamp = NSDate.ows_millisecondsSince1970(for: Date())
        let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: thread, messageBody: wrapper.content)

        guard let datasource = DataSourceValue.dataSource(with: videoData, fileExtension: "mov") else { return }

        messageSender?.sendAttachmentData(datasource, contentType: "video/mp4", sourceFilename: "video.mp4", in: outgoingMessage, success: { [weak self] in
            self?.output?.didFinishRequest()
            DLog("Success")
        }, failure: { [weak self] error in
            self?.output?.didFinishRequest()
            DLog("Failure: \(error)")
            self?.logSendErrorIfRecipientUnregistered(error: error)
        })
    }

    func retrieveRecipientAddress(completion: @escaping (String?) -> Void) {
        guard let tokenId = thread.contactIdentifier() else { return }

        idAPIClient.retrieveUser(username: tokenId) { user in
            guard let user = user else {
                assertionFailure("can't retrieve recipient's payment address")
                completion(nil)
                return
            }

            completion(user.paymentAddress)
        }
    }

    func fetchAndUpdateBalance(cachedCompletion: @escaping BalanceCompletion, fetchedCompletion: @escaping BalanceCompletion) {
        etherAPIClient.getBalance(cachedBalanceCompletion: { cachedBalance, _ in
            cachedCompletion(cachedBalance, nil)
        }, fetchedBalanceCompletion: { fetchedBalance, error in
            fetchedCompletion(fetchedBalance, error)
        })
    }

    func sendPayment(with parameters: [String: Any], transaction: String?, completion: ((Bool) -> Void)? = nil) {

        guard let transaction = transaction else {
            self.output?.didFinishRequest()
            completion?(false)

            return
        }

        let signedTransaction = "0x\(Cereal.shared.signWithWallet(hex: transaction))"

        self.etherAPIClient.sendSignedTransaction(originalTransaction: transaction, transactionSignature: signedTransaction) { [weak self] success, transactionHash, error in

            self?.output?.didFinishRequest()

            guard success, let txHash = transactionHash else {
                self?.output?.didCatchError(error?.description ?? ToshiError.genericError.description)
                completion?(false)

                return
            }
            
            guard let value = parameters[PaymentParameters.value] as? String else { return }

            let payment = SofaPayment(txHash: txHash, valueHex: value)
            self?.sendMessage(sofaWrapper: payment)

            DispatchQueue.main.async {
                completion?(true)
            }
        }
    }
    
    private func logSendErrorIfRecipientUnregistered(error: Error?) {
        guard let error = error else { return }

        if error.localizedDescription == "ERROR_DESCRIPTION_UNREGISTERED_RECIPIENT" {
            CrashlyticsLogger.nonFatal("Could not send message because recipient was unregistered", error: (error as NSError), attributes: nil)
        }
    }
    
    // MARK: - Receiving

    func handleInvalidKeyError(_: TSInvalidIdentityKeyErrorMessage) {
    }

    /// Handle incoming interactions or previous messages when restoring a conversation.
    ///
    /// - Parameters:
    ///   - interaction: the interaction to handle. Incoming/outgoing messages, wrapping SOFA structures.
    ///   - shouldProcessCommands: If true, will process a sofa wrapper. This means replying to requests, displaying payment UI etc.
    ///   - shouldUpdateGroupMembers: If true will go over group members IDs and update with calling id service and download avatar
    func handleSignalMessage(_ signalMessage: TSMessage, shouldProcessCommands: Bool = false, shouldUpdateGroupMembers: Bool = false) -> Message {
        if let invalidKeyErrorMessage = signalMessage as? TSInvalidIdentityKeySendingErrorMessage {
            DispatchQueue.main.async {
                self.handleInvalidKeyError(invalidKeyErrorMessage)
            }

            return Message(sofaWrapper: nil, signalMessage: invalidKeyErrorMessage, date: invalidKeyErrorMessage.dateForSorting(), isOutgoing: false)
        }

        if let infoMessage = signalMessage as? TSInfoMessage {
            return handleSignalInfoMessage(infoMessage, shouldUpdateGroupMembers: shouldUpdateGroupMembers)
        }

        if shouldProcessCommands {
            let type = SofaType(sofa: signalMessage.body)
            switch type {
            case .initialRequest:
                let initialResponse = SofaInitialResponse(initialRequest: SofaInitialRequest(content: signalMessage.body ?? ""))
                sendMessage(sofaWrapper: initialResponse)
            default:
                break
            }
        }

        /// TODO: Simplify how we deal with interactions vs text messages.
        /// Since now we know we can expand the TSInteraction stored properties, maybe we can merge some of this together.
        if let interaction = signalMessage as? TSOutgoingMessage {
            let sofaWrapper = SofaWrapper.wrapper(content: interaction.body ?? "")

            if interaction.body != sofaWrapper.content {
                interaction.body = sofaWrapper.content
                interaction.save()
            }
            
            let message = Message(sofaWrapper: sofaWrapper, signalMessage: interaction, date: interaction.dateForSorting(), isOutgoing: true)

            if interaction.hasAttachments() {
                message.messageType = "Image"
            } else if let payment = SofaWrapper.wrapper(content: interaction.body ?? "") as? SofaPayment {
                // TODO: Figure out what this should be instead of actionable https://toshiapp.atlassian.net/browse/IOS-456
                message.messageType = "Actionable"
                message.attributedTitle = NSAttributedString(string: Localized("chat_payment_sent"), attributes: [.foregroundColor: Theme.outgoingMessageTextColor, .font: Theme.medium(size: 17)])
                message.attributedSubtitle = NSAttributedString(string: EthereumConverter.balanceAttributedString(forWei: payment.value, exchangeRate: ExchangeRateClient.exchangeRate).string, attributes: [.foregroundColor: Theme.outgoingMessageTextColor, .font: Theme.regular(size: 15)])
            }

            return message
        } else if let interaction = signalMessage as? TSIncomingMessage {
            let sofaWrapper = SofaWrapper.wrapper(content: interaction.body ?? "")

            if interaction.body != sofaWrapper.content {
                interaction.body = sofaWrapper.content
                interaction.save()
            }
            
            let message = Message(sofaWrapper: sofaWrapper, signalMessage: interaction, date: interaction.dateForSorting(), isOutgoing: false, shouldProcess: shouldProcessCommands && interaction.paymentState == .none)

            if interaction.hasAttachments() {
                message.messageType = "Image"
            } else if let paymentRequest = sofaWrapper as? SofaPaymentRequest {
                message.messageType = "Actionable"
                message.title = Localized("chat_payment_request_action")
                message.attributedSubtitle = EthereumConverter.balanceAttributedString(forWei: paymentRequest.value, exchangeRate: ExchangeRateClient.exchangeRate)
            } else if let payment = sofaWrapper as? SofaPayment {
                output?.didFinishRequest()
                message.messageType = "Actionable"
                message.attributedTitle = NSAttributedString(string: Localized("chat_payment_recieved"), attributes: [.foregroundColor: Theme.incomingMessageTextColor, .font: Theme.medium(size: 17)])
                message.attributedSubtitle = NSAttributedString(string: EthereumConverter.balanceAttributedString(forWei: payment.value, exchangeRate: ExchangeRateClient.exchangeRate).string, attributes: [.foregroundColor: Theme.incomingMessageTextColor, .font: Theme.regular(size: 15)])
            }

            return message
        } else {
            return Message(sofaWrapper: nil, signalMessage: signalMessage, date: signalMessage.dateForSorting(), isOutgoing: false)
        }
    }

    func playSound(for message: Message) {
        if message.isOutgoing {
            if message.sofaWrapper?.type == .paymentRequest {
                SoundPlayer.playSound(type: .requestPayment)
            } else if message.sofaWrapper?.type == .payment {
                SoundPlayer.playSound(type: .paymentSend)
            } else {
                SoundPlayer.playSound(type: .messageSent)
            }
        } else {
            SoundPlayer.playSound(type: .messageReceived)
        }
    }
    
    @discardableResult static func getOrCreateThread(for address: String) -> TSThread {
        var thread: TSThread?

        TSStorageManager.shared().dbReadWriteConnection?.readWrite { transaction in
            var recipient = SignalRecipient(textSecureIdentifier: address, with: transaction)

            var shouldRequestContactsRefresh = false

            if recipient == nil {
                recipient = SignalRecipient(textSecureIdentifier: address, relay: nil)
                shouldRequestContactsRefresh = true

                IDAPIClient.shared.updateContact(with: address)
            }

            recipient?.save(with: transaction)
            thread = TSContactThread.getOrCreateThread(withContactId: address, transaction: transaction)

            if shouldRequestContactsRefresh == true {
                self.requestContactsRefresh()
            }

            if thread?.archivalDate() != nil {
                thread?.unarchiveThread(with: transaction)
            }
        }

        return thread!
    }

    // MARK: - Groups
    
    public static func updateGroup(with groupModel: TSGroupModel, completion: @escaping ((Bool) -> Void)) {
        var thread: TSGroupThread?
        var oldModel: TSGroupModel?

        TSStorageManager.shared().dbReadWriteConnection?.readWrite { transaction in
            thread = TSGroupThread.getOrCreateThread(with: groupModel, transaction: transaction)

            oldModel = thread?.groupModel

            guard let fetchedThread = thread else {
                CrashlyticsLogger.log("Failed to retrieve thread from DB while updating")
                return
            }

            fetchedThread.groupModel = groupModel
            fetchedThread.save(with: transaction)
        }

        guard let updatedThread = thread, let oldGroupModel = oldModel else {
            CrashlyticsLogger.log("Failed to retrieve thread and old group model from DB while updating")
            return
        }

        sendGroupUpdateMessage(to: updatedThread, from: oldGroupModel, to: groupModel, completion: completion)
    }

    public static func createGroup(with recipientsIds: NSMutableArray, name: String, avatar: UIImage, completion: @escaping ((Bool) -> Void)) {

        let groupId = Randomness.generateRandomBytes(16)

        guard let groupModel = TSGroupModel(title: name, memberIds: recipientsIds, image: avatar, groupId: groupId) else { return }

        var thread: TSGroupThread?
        TSStorageManager.shared().dbReadWriteConnection?.readWrite { transaction in
            thread = TSGroupThread.getOrCreateThread(with: groupModel, transaction: transaction)
        }

        guard thread != nil else { return }

        ProfileManager.shared().addThread(toProfileWhitelist: thread!)

        Navigator.tabbarController?.openThread(thread!)

        sendInitialGroupMessage(to: thread!, completion: completion)
    }

    private func handleSignalInfoMessage(_ infoMessage: TSInfoMessage, shouldUpdateGroupMembers: Bool = false) -> Message {
        let customMessage = infoMessage.customMessage
        let updateInfoString = infoMessage.additionalInfoString
        let authorId = infoMessage.authorId

        if let thread = infoMessage.thread as? TSGroupThread {

            var object = ""
            var subject = ""
            var statusType = SofaStatus.StatusType.none

            if let author = SessionManager.shared.contactsManager.tokenContact(forAddress: authorId) {
                subject = author.nameOrDisplayName
            } else if authorId == Cereal.shared.address {
                subject = Localized("current_user_pronoun")
            } else {
                idAPIClient.updateContact(with: authorId)
            }

            switch customMessage {
            case GroupCreateMessage:
                statusType = .created
                subject = updateInfoString
            case GroupBecameMemberMessage:
                statusType = .becameMember
                subject = updateInfoString
            case GroupTitleChangedMessage:
                statusType = .rename
                object = updateInfoString
            case GroupAvatarChangedMessage:
                statusType = .changePhoto
            case GroupMemberLeftMessage:
                statusType = .leave
            case GroupMemberJoinedMessage:
                statusType = .added

                if shouldUpdateGroupMembers {
                    thread.updateGroupMembers()
                }

                object = userWhoJoinedNamesString(for: updateInfoString)

                if shouldUpdateGroupMembers {
                    ChatInteractor.requestContactsRefresh()
                }

            default:
                break
            }

            let status = SofaStatus(content: "SOFA::Status:{\"type\":\"\(statusType.rawValue)\",\"subject\":\"\(subject)\",\"object\":\"\(object)\"}")
            let message = Message(sofaWrapper: status, signalMessage: infoMessage, date: infoMessage.dateForSorting(), isOutgoing: false)

            return message
        }

        return Message(sofaWrapper: nil, signalMessage: infoMessage, date: infoMessage.dateForSorting(), isOutgoing: false)
    }

    private func userWhoJoinedNamesString(for infoMessageString: String) -> String {
        let namesOrAddresses = infoMessageString.components(separatedBy: ",")
        var resultNames: [String] = []

        for nameOrAddress in namesOrAddresses.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) {
            resultNames.append(nameOrTruncatedAddress(for: nameOrAddress))
        }

        return resultNames.joined(separator: ", ")
    }

    private func nameOrTruncatedAddress(for nameOrAddress: String) -> String {

        if nameOrAddress.hasAddressPrefix {
            let validDisplayName = SessionManager.shared.contactsManager.displayName(forPhoneIdentifier: nameOrAddress)
            if !validDisplayName.isEmpty {
                return validDisplayName
            } else {
                return nameOrAddress.truncate(length: 10)
            }
        }

        return nameOrAddress
    }

    private static func sendGroupUpdateMessage(to thread: TSGroupThread, from oldGroupViewModel: TSGroupModel, to newGroupModel: TSGroupModel, completion: @escaping ((Bool) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let timestamp = NSDate.ows_millisecondTimeStamp()
            let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: thread, groupMetaMessage: TSGroupMetaMessage.update)

            if let updateGroupInfo = oldGroupViewModel.getInfoAboutUpdate(to: newGroupModel) {
                outgoingMessage.update(withCustomInfo: updateGroupInfo)
            }

            let interactor = ChatInteractor(output: nil, thread: thread)
            let image = newGroupModel.avatarOrPlaceholder
            interactor.send(image: image, in: outgoingMessage, completion: completion)
        }
    }

    private static func sendInitialGroupMessage(to thread: TSGroupThread, completion: @escaping ((Bool) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let timestamp = NSDate.ows_millisecondTimeStamp()
            let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: thread, groupMetaMessage: TSGroupMetaMessage.new)
            let customInfo = [GroupUpdateTypeSting: GroupCreateMessage]
            outgoingMessage.update(withCustomInfo: customInfo)

            let interactor = ChatInteractor(output: nil, thread: thread)

            if let groupAvatar = thread.groupModel.groupImage {
                interactor.send(image: groupAvatar, in: outgoingMessage, completion: completion)
            } else {
                interactor.send(outgoingMessage, completion: completion)
            }
        }
    }

    static func sendLeaveGroupMessage(_ thread: TSGroupThread, completion: ((Bool) -> Void)? = nil) {

        DispatchQueue.global(qos: .background).async {
            let timestamp = NSDate.ows_millisecondTimeStamp()
            let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: thread, groupMetaMessage: TSGroupMetaMessage.quit)

            let interactor = ChatInteractor(output: nil, thread: thread)
            interactor.send(outgoingMessage, completion: { success in
                if success {
                    ChatInteractor.deleteThread(thread)
                    DLog("Successfully left a group")
                } else {
                    DLog("Failed to leave a group")
                }
                
                guard let completion = completion else { return }
                DispatchQueue.main.async {
                    completion(success)
                }
            })

            var newGroupMembersIds = thread.groupModel.groupMemberIds

            if let userAddressIndex = newGroupMembersIds?.index(of: Cereal.shared.address) {
                newGroupMembersIds?.remove(at: userAddressIndex)
            }

            thread.groupModel.groupMemberIds = newGroupMembersIds
            thread.save()
        }
    }
    
    static func sendRequestForGroupInfo(for thread: TSGroupThread, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let timestamp = NSDate.ows_millisecondTimeStamp()
            let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: thread, groupMetaMessage: TSGroupMetaMessage.requestInfo)
            outgoingMessage.body = "REQUEST_INFO"
            
            let interactor = ChatInteractor(output: nil, thread: thread)
            
            interactor.send(outgoingMessage, completion: completion)
        }
    }
    
    // MARK: - Deletion
    
    static func deleteThread(_ thread: TSThread) {
        TSStorageManager.shared().dbReadWriteConnection?.asyncReadWrite { transaction in
            thread.remove(with: transaction)
            thread.markAllAsRead(with: transaction)
        }
    }
    
    // MARK: - Bots

    static func triggerBotGreeting() {
        guard let botAddress = Bundle.main.infoDictionary?["InitialGreetingAddress"] as? String else { return }

        let botThread = ChatInteractor.getOrCreateThread(for: botAddress)
        let interactor = ChatInteractor(output: nil, thread: botThread)

        let initialRequest = SofaInitialRequest(content: ["values": ["paymentAddress", "language"]])
        let initWrapper = SofaInitialResponse(initialRequest: initialRequest)
        interactor.sendMessage(sofaWrapper: initWrapper)
    }
    
    // MARK: - Updating Contacts

    private static func requestContactsRefresh() {
        SessionManager.shared.contactsManager.refreshContacts()
    }

    func sendImage(_ image: UIImage, in message: TSOutgoingMessage? = nil) {

        let wrapper = SofaMessage(body: "")
        let timestamp = NSDate.ows_millisecondsSince1970(for: Date())

        guard let data = UIImageJPEGRepresentation(image, 0.7) else {
            DLog("Cant convert selected image to data")
            return
        }

        let outgoingMessage = message ?? TSOutgoingMessage(timestamp: timestamp, in: self.thread, messageBody: wrapper.content)

        guard let datasource = DataSourceValue.dataSource(with: data, fileExtension: "jpeg") else { return }

        self.messageSender?.sendAttachmentData(datasource, contentType: "image/jpeg", sourceFilename: "File.jpeg", in: outgoingMessage, success: {
            DLog("Success")
        }, failure: { error in
            DLog("Failure: \(error)")
        })
    }

    static func acceptThread(_ thread: TSThread) {
        thread.isPendingAccept = false
        thread.save()

        if let contactIdentifier = thread.contactIdentifier() {
            IDAPIClient.shared.updateContact(with: contactIdentifier)
        }
    }

    static func declineThread(_ thread: TSThread, completion: ((Bool) -> Void)? = nil) {
        if let groupThread = thread as? TSGroupThread {
            sendLeaveGroupMessage(groupThread, completion: completion)
        } else if let contactIdentifier = thread.contactIdentifier() {

            thread.isPendingAccept = false
            thread.save()

            OWSBlockingManager.shared().addBlockedPhoneNumber(contactIdentifier)
            deleteThread(thread)
            completion?(true)
        }
    }
}
