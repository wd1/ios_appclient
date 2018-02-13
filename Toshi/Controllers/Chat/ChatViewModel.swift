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

enum DisplayState {
    case hide
    case show
    case hideAndShow
    case doNothing
}

protocol ChatViewModelOutput: ChatInteractorOutput {
    func didReload()
    func didRequireGreetingIfNeeded()
    func didRequireKeyboardVisibilityUpdate(_ sofaMessage: SofaMessage)
    func didReceiveLastMessage()
}

final class ChatViewModel {

    private weak var output: ChatViewModelOutput?

    init(output: ChatViewModelOutput, thread: TSThread) {
        self.output = output
        self.thread = thread

        storageManager = TSStorageManager.shared()

        countAllMessages()

        registerNotifications()

        contactsManager = SessionManager.shared.contactsManager
    }

    private var contactsManager: ContactsManager?

    private var etherAPIClient: EthereumAPIClient {
        return EthereumAPIClient.shared
    }

    private(set) var thread: TSThread

    private(set) lazy var interactor: ChatInteractor = {
        ChatInteractor(output: self.output, thread: self.thread)
    }()

    var contact: TokenUser? {
        return contactsManager?.tokenContact(forAddress: thread.contactIdentifier())
    }

    var currentButton: SofaMessage.Button?

    var messageModels: [MessageModel] = []

    private lazy var reloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "Chat-Reload-Queue"

        return queue
    }()

    private(set) var messages: [Message] = [] {
        didSet {
            reloadQueue.cancelAllOperations()

            let operation = BlockOperation()
            operation.addExecutionBlock { [weak self] in

                guard operation.isCancelled == false else { return }
                guard let strongSelf = self else { return }

                for message in strongSelf.messages {
                    if let paymentRequest = message.sofaWrapper as? SofaPaymentRequest {
                        message.fiatValueString = paymentRequest.fiatValueString
                        message.ethereumValueString = EthereumConverter.ethereumValueString(forWei: paymentRequest.value)
                    } else if let payment = message.sofaWrapper as? SofaPayment {
                        message.fiatValueString = payment.fiatValueString
                        message.ethereumValueString = EthereumConverter.ethereumValueString(forWei: payment.value)
                    }
                }

                strongSelf.visibleMessages = strongSelf.messages.filter { message -> Bool in
                    message.isDisplayable
                }

                guard operation.isCancelled == false else { return }

                DispatchQueue.main.async {
                    strongSelf.output?.didReload()
                }
            }

            reloadQueue.addOperation(operation)
        }
    }

    var visibleMessages: [Message] = [] {
        didSet {
            messageModels = visibleMessages.flatMap { MessageModel(message: $0) }
        }
    }

    func loadFirstMessages() {
        loadNextChunk(notifiesAboutLastMessage: true)
    }

    func visibleMessage(at index: Int) -> Message {
        return visibleMessages[index]
    }

    func message(at index: Int) -> Message {
        return messages[index]
    }

    private var storageManager: TSStorageManager?

    private lazy var uiDatabaseConnection: YapDatabaseConnection = {
        let database = TSStorageManager.shared().database()!
        let dbConnection = database.newConnection()
        dbConnection.beginLongLivedReadTransaction()

        return dbConnection
    }()

    private lazy var rangeOptions: YapDatabaseViewRangeOptions = {
        let options = YapDatabaseViewRangeOptions.flexibleRange(withLength: 20, offset: 0, from: .end)!
        options.growOptions = .onBothSides

        return options
    }()

    private lazy var mappings: YapDatabaseViewMappings = {
        YapDatabaseViewMappings(groups: [self.thread.uniqueId], view: TSMessageDatabaseViewExtensionName)
    }()

    private lazy var loadedMappings: YapDatabaseViewMappings = {
        YapDatabaseViewMappings(groups: [self.thread.uniqueId], view: TSMessageDatabaseViewExtensionName)
    }()

    private lazy var editingDatabaseConnection: YapDatabaseConnection? = {
        self.storageManager?.newDatabaseConnection()
    }()

    private var messagesCount: UInt = 0
    private var loadedMessagesCount: UInt = 0

    private func registerNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
    }

    func saveDraftIfNeeded(inputViewText: String?) {
        let thread = self.thread
        guard let text = inputViewText else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            self.editingDatabaseConnection?.asyncReadWrite { transaction in
                thread.setDraft(text, transaction: transaction)
            }
        }
    }

    func updateMessagesRange(from indexPath: IndexPath? = nil) {
        loadNextChunk()
    }

    private func loadNextChunk(notifiesAboutLastMessage: Bool = false) {
        let nextChunkSize = self.nextChunkSize()

        guard let rangeOptions = YapDatabaseViewRangeOptions.flexibleRange(withLength: nextChunkSize, offset: loadedMessagesCount, from: .end) else {
            self.output?.didRequireGreetingIfNeeded()
            
            return
        }

        self.loadedMappings.setRangeOptions(rangeOptions, forGroup: self.thread.uniqueId)

        self.loadMessages(notifiesAboutLastMessage: notifiesAboutLastMessage)
    }

    @objc
    private func yapDatabaseDidChange(notification _: NSNotification) {
        
        let notifications = uiDatabaseConnection.beginLongLivedReadTransaction()

        // If changes do not affect current view, update and return without updating collection view
        // TODO: Since this is used in more than one place, we should look into abstracting this away, into our own
        // table/collection view backing model.
        // swiftlint:disable:next force_cast
        let messageViewConnection = uiDatabaseConnection.ext(TSMessageDatabaseViewExtensionName) as! YapDatabaseViewConnection
        if messageViewConnection.hasChanges(for: notifications) == false {
            uiDatabaseConnection.read { transaction in
                self.mappings.update(with: transaction)
            }

            return
        }

        let yapDatabaseChanges = messageViewConnection.getChangesFor(notifications: notifications, with: mappings)

        uiDatabaseConnection.asyncRead { [weak self] transaction in
            guard let strongSelf = self else { return }

            strongSelf.mappings.update(with: transaction)
            strongSelf.loadedMappings.update(with: transaction)

            for change in yapDatabaseChanges.rowChanges {

                guard let dbExtension = transaction.ext(TSMessageDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { return }

                guard let newIndexPath = change.newIndexPath else { continue }

                switch change.type {
                case .insert:
                    guard let signalMessage = dbExtension.object(at: newIndexPath, with: strongSelf.mappings) as? TSMessage else { return }

                    DispatchQueue.main.async {
                        let result = strongSelf.interactor.handleSignalMessage(signalMessage, shouldProcessCommands: true, shouldUpdateGroupMembers: true)

                        strongSelf.messages.insert(result, at: 0)

                        strongSelf.output?.didReceiveLastMessage()

                        if let sofaMessage = result.sofaWrapper as? SofaMessage {
                            strongSelf.output?.didRequireKeyboardVisibilityUpdate(sofaMessage)
                        }

                        strongSelf.interactor.playSound(for: result)
                    }

                case .update:
                    guard let indexPath = change.indexPath else { continue }

                    guard let signalMessage = dbExtension.object(at: indexPath, with: strongSelf.mappings) as? TSMessage else { return }
                    guard let message = strongSelf.messages.first(where: { $0.signalMessage.uniqueId == signalMessage.uniqueId }) else { return }
                    
                    DispatchQueue.main.async {
                        if let loadedSignalMessage = message.signalMessage as? TSOutgoingMessage, let newSignalMessage = signalMessage as? TSOutgoingMessage {
                            loadedSignalMessage.setState(newSignalMessage.messageState)
                        }

                        if let index = strongSelf.messages.index(of: message) {

                            let updatedMessage = strongSelf.interactor.handleSignalMessage(signalMessage, shouldProcessCommands: true)
                            strongSelf.messages[index] = updatedMessage
                        }
                    }
                default:
                    break
                }
            }
        }
    }

    func reloadDraft(completion: @escaping ((String?) -> Void)) {
        let thread = self.thread
        var placeholder: String?

        DispatchQueue.global(qos: .userInitiated).async {
            self.editingDatabaseConnection?.asyncReadWrite({ transaction in
                placeholder = thread.currentDraft(with: transaction)
            }, completionBlock: {
                DispatchQueue.main.async {
                    completion(placeholder)
                }
            })
        }
    }

    func displayState(for button: SofaMessage.Button?) -> DisplayState {
        if let button = button, let currentButton = self.currentButton {
            if button == currentButton {
                return .hide
            } else {
                return .hideAndShow
            }
        }

        if button == nil && currentButton == nil {
            return .doNothing
        } else if button == nil && currentButton != nil {
            return .hide
        } else {
            return .show
        }
    }

    func fetchAndUpdateBalance(cachedCompletion: @escaping BalanceCompletion, fetchedCompletion: @escaping BalanceCompletion) {
        interactor.fetchAndUpdateBalance(cachedCompletion: cachedCompletion, fetchedCompletion: fetchedCompletion)
    }

    private func countAllMessages() {
        self.uiDatabaseConnection.read { [weak self] transaction in
            guard let strongSelf = self else { return }

            strongSelf.mappings.update(with: transaction)
            strongSelf.messagesCount = strongSelf.mappings.numberOfItems(inSection: 0)
        }
    }

    private func nextChunkSize() -> UInt {
        let notLoadedCount = messagesCount - loadedMessagesCount
        let numberToLoad = min(notLoadedCount, 50)

        return numberToLoad
    }

    func loadMessages(notifiesAboutLastMessage: Bool) {
        uiDatabaseConnection.asyncRead { [weak self] transaction in
            guard let strongSelf = self else { return }
            strongSelf.loadedMappings.update(with: transaction)

            var messages = [Message]()

            let numberOfItemsInSection = strongSelf.loadedMappings.numberOfItems(inSection: 0)
            strongSelf.loadedMessagesCount += numberOfItemsInSection

            for i in 0 ..< numberOfItemsInSection {
                let indexPath = IndexPath(row: Int(i), section: 0)
                guard let dbExtension = transaction.ext(TSMessageDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { return }

                guard let signalMessage = dbExtension.object(at: indexPath, with: strongSelf.loadedMappings) as? TSMessage else { return }

                var shouldProcess = false
                if SofaType(sofa: signalMessage.body ?? "") == .paymentRequest {
                    shouldProcess = true
                }

                messages.append(strongSelf.interactor.handleSignalMessage(signalMessage, shouldProcessCommands: shouldProcess))
            }

            let current = Set(messages)
            let previous = Set(strongSelf.messages)
            let new = current.subtracting(previous).sorted { (message1, message2) -> Bool in
                // Signal splits media message in two separate messages, one with the attachments and one with text.
                // In this case two messages have the same Timestamp, we want to have the one with an attachment on top.
                if message1.date.compare(message2.date) == .orderedSame {
                    return message1.signalMessage.hasAttachments()
                }

                return message1.date.compare(message2.date) == .orderedAscending
            }.reversed()

            DispatchQueue.main.async {
                strongSelf.messages.append(contentsOf: new)

                if notifiesAboutLastMessage {
                    strongSelf.output?.didReceiveLastMessage()
                }
            }
        }
    }

    func markAllMessagesAsRead() {
        TSStorageManager.shared().dbReadWriteConnection?.asyncReadWrite { [weak self] transaction in
            self?.thread.markAllAsRead(with: transaction)

            SignalNotificationManager.updateUnreadMessagesNumber()
        }
    }
    
    func deleteItemAt(_ indexPath: IndexPath) {
        
        if let message = messageModels.element(at: indexPath.item)?.signalMessage {
            
            TSStorageManager.shared().dbReadWriteConnection?.asyncReadWrite { [weak self] transaction in
                
                message.remove(with: transaction)
                
                DispatchQueue.main.async {
                    self?.messages.remove(at: indexPath.item)
                }
            }
        }
    }
    
    func resendItemAt(_ indexPath: IndexPath) {

        if let message = messageModels.element(at: indexPath.item)?.signalMessage as? TSOutgoingMessage {
            interactor.send(message)
        }
    }
}
