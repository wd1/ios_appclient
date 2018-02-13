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

protocol PaymentRouterDelegate: class {
    func paymentRouterDidCancel(paymentRouter: PaymentRouter)
    func paymentRouterDidSucceedPayment(_ paymentRouter: PaymentRouter, parameters: [String: Any], transactionHash: String?, unsignedTransaction: String?, error: ToshiError?)
}

extension PaymentRouterDelegate {
    func paymentRouterDidCancel(paymentRouter: PaymentRouter) {}
}

final class PaymentRouter {
    weak var delegate: PaymentRouterDelegate?

    var userInfo: UserInfo?
    var dappInfo: DappInfo?
    private var shouldSendSignedTransaction = true

    /// We keep track of how many controllers the payment router has in stack, so we can identify when the whole payment is being cancelled.
    private var controllersInStackCount = 0

    private var paymentViewModel: PaymentViewModel

    init(parameters: [String: Any] = [:], shouldSendSignedTransaction: Bool = true) {
        self.shouldSendSignedTransaction = shouldSendSignedTransaction
        self.paymentViewModel = PaymentViewModel(parameters: parameters)
    }

    func present() {
        increaseControllersStack()

        guard let value = paymentViewModel.value else {
            presentPaymentValueController()
            return
        }

        guard let address = paymentViewModel.recipientAddress else {
            presentRecipientAddressController(withValue: value)
            return
        }

        presentPaymentConfirmationController(withValue: value, andRecipientAddress: address)
    }

    private func increaseControllersStack() {
        controllersInStackCount += 1
    }

    private func decreaseControllersStack() {
        controllersInStackCount -= 1
    }

    private func cancelIfNeeded() {
        let hasDismissedPaymentRouterFlow = (controllersInStackCount == 0)
        guard hasDismissedPaymentRouterFlow else { return }

        delegate?.paymentRouterDidCancel(paymentRouter: self)
    }

    private func presentPaymentValueController() {
        let paymentValueController = PaymentValueViewController(withPaymentType: .send, continueOption: .next)
        paymentValueController.delegate = self

        presentViewControllerOnNavigator(paymentValueController)
    }

    private func presentRecipientAddressController(withValue value: NSDecimalNumber) {
        let addressController = PaymentAddressViewController(with: value)
        addressController.delegate = self

        presentViewControllerOnNavigator(addressController)
    }

    private func presentPaymentConfirmationController(withValue value: NSDecimalNumber, andRecipientAddress address: String) {

        if let dappInfo = dappInfo {
            let paymentConfirmationController = PaymentConfirmationViewController(parameters: paymentViewModel.parameters, recipientType: .dapp(info: dappInfo), shouldSendSignedTransaction: shouldSendSignedTransaction)

            paymentConfirmationController.backgroundView = Navigator.window?.snapshotView(afterScreenUpdates: false)

            paymentConfirmationController.delegate = self
            paymentConfirmationController.presentationMethod = .modalBottomSheet

            Navigator.presentModally(paymentConfirmationController)
        } else {
            let paymentConfirmationController = PaymentConfirmationViewController(parameters: paymentViewModel.parameters, recipientType: .user(info: userInfo), shouldSendSignedTransaction: shouldSendSignedTransaction)
            paymentConfirmationController.delegate = self

            let navigationController = PaymentNavigationController(rootViewController: paymentConfirmationController)
            Navigator.presentModally(navigationController)
        }
    }

    private func presentViewControllerOnNavigator(_ controller: UIViewController) {

        if controller is PaymentConfirmationViewController {
            let navigationController = PaymentNavigationController(rootViewController: controller)
            Navigator.presentModally(navigationController)
        } else if let paymentNavigationController = Navigator.topViewController as? PaymentNavigationController {
            paymentNavigationController.pushViewController(controller, animated: true)
        } else {
            let navigationController = PaymentNavigationController(rootViewController: controller)
            Navigator.presentModally(navigationController)
        }
    }
}

extension PaymentRouter: PaymentValueViewControllerDelegate {
    func paymentValueViewControllerControllerFinished(with valueInWei: NSDecimalNumber, on controller: PaymentValueViewController) {
        paymentViewModel.value = valueInWei
        present()
    }

    func paymentValueControllerDidCancel(_ controller: PaymentValueViewController) {
        decreaseControllersStack()

        cancelIfNeeded()
    }
}

extension PaymentRouter: PaymentAddressControllerDelegate {
    func paymentAddressControllerFinished(with address: String, on controller: PaymentAddressViewController) {
        paymentViewModel.recipientAddress = address
        present()
    }

    func paymentAddressControllerDidCancel(_ controller: PaymentAddressViewController) {
        decreaseControllersStack()
    }
}

extension PaymentRouter: PaymentConfirmationViewControllerDelegate {

    func paymentConfirmationViewControllerFinished(on controller: PaymentConfirmationViewController, parameters: [String: Any], transactionHash: String?, error: ToshiError?) {

        guard let tabBarController = Navigator.tabbarController,
              let selectedNavigationController = tabBarController.selectedViewController as? UINavigationController,
              let firstPaymentPresentedController = selectedNavigationController.presentedViewController else { return }

        // Top view controller is always the last one from payment related stack, important to dismiss without animation
        Navigator.topViewController?.dismiss(animated: false, completion: {
            // First present controller in the stack is first in payment related flow, the very root payment related navigation controller which is presented
            // dismissing it - it last step
            firstPaymentPresentedController.dismiss(animated: true, completion: nil)
        })

        self.delegate?.paymentRouterDidSucceedPayment(self, parameters: parameters, transactionHash: transactionHash, unsignedTransaction: controller.originalUnsignedTransaction, error: error)
    }

    func paymentConfirmationViewControllerDidCancel(_ controller: PaymentConfirmationViewController) {
        decreaseControllersStack()
        cancelIfNeeded()
    }
}
