

import UIKit

protocol MakeDepositRoutingLogic {
    func routeToMultiplePaymentMethods()
    func routeToPayment(value: Amount.Value) throws
    func routeToApplication()
}

protocol MakeDepositParentRoutingLogic {
    func routeToMultiplePaymentMethods()
    func routeToSummary(with summary: PaymentSummary)
    func routeToError(with error: AnyError)
    func returnFromMakeDeposit()
}

enum MakeDepositRoutingError: Error {
    case couldNotCreatePaymentController
}

class MakeDepositRouter {
    let parentRouter: MakeDepositParentRoutingLogic
    weak var viewController: UIViewController!
    private let viewControllerFactory: MakeDepositViewControllerFactory
    private let pesProvider: PESProvider
    
    init(parentRouter: MakeDepositParentRoutingLogic,
         viewController: UIViewController,
         viewControllerFactory: MakeDepositViewControllerFactory,
         pesProvider: PESProvider) {
        self.parentRouter = parentRouter
        self.viewController = viewController
        self.viewControllerFactory = viewControllerFactory
        self.pesProvider = pesProvider
    }
}

extension MakeDepositRouter: MakeDepositRoutingLogic {
    func routeToMultiplePaymentMethods() {
        parentRouter.routeToMultiplePaymentMethods()
    }
    
    func routeToPayment(value: Amount.Value) throws {
        guard let paymentViewController = viewControllerFactory.makePaymentViewController(amountValue: value, parentRouter: self) else {
            throw MakeDepositRoutingError.couldNotCreatePaymentController
        }
        viewController.present(paymentViewController, animated: true, completion: nil)
    }

    func routeToApplication() {
        parentRouter.returnFromMakeDeposit()
    }
}

extension MakeDepositRouter: PaymentParentRoutingLogic {
    func routeToSummary(with summary: PaymentSummary) {
        viewController.dismiss(animated: true) { [weak self] in
            self?.parentRouter.routeToSummary(with: summary)
        }
    }
    
    func routeToError(with error: AnyError) {
        viewController.dismiss(animated: true)
        parentRouter.routeToError(with: error)
    }
    
    func returnFromPayment() {
        viewController.dismiss(animated: true)
    }
}
