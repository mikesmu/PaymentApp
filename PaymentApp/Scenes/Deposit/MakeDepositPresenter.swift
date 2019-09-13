

protocol MakeDepositPresentationLogic {
    func present(amount: Amount?)
    func present(validationError: MakeDepositBusinessLogicError)
    func presentAmountValidationSuccess()
    func presentMultiplePaymentMethods()
    func presentPaymentAuthorization(value: Amount.Value)
    func presentPOCFStateChange(hidden: Bool)
}

struct MakeDepositPresenter {
    weak var view: MakeDepositViewLogic!
    private let errorAmountFormatter: AmountFormatter
    private let amountValueFormatter: AmountValueFormatter
    private let currencyFormatter: AmountCurrencyFormatter
    
    init(view: MakeDepositViewLogic) {
        self.view = view
        let formatter = DefaultAmountFormatter()
        self.errorAmountFormatter = formatter
        self.amountValueFormatter = formatter
        self.currencyFormatter = formatter
    }
}

extension MakeDepositPresenter: MakeDepositPresentationLogic {
    func present(amount: Amount?) {
        guard let amount = amount, !amount.isEmpty else {
            view.display(formattedAmountValue: nil)
            return
        }
        do {
            let formattedValue = try amountValueFormatter.format(amountValue: amount.value)
            view.display(formattedAmountValue: formattedValue)
        } catch let error as AmountFormattingError {
            Logger.warning("Presenting amount \"\(amount)\" failed with an error: \"\(error)\"")
            view.displayAmountValidationFailure(with: error.localizedDescription)
        } catch {
            let errorMessage = "Unknown error occured when presenting amount \(error)"
            Logger.error(errorMessage)
            assertionFailure(errorMessage)
        }
    }
    
    func presentMultiplePaymentMethods() {
        view.displayMultiplePaymentMethods()
    }

    func present(validationError: MakeDepositBusinessLogicError) {
        switch validationError {
        case .amountParsingError(let parsingError):
            presentAmountParsingError(parsingError)
        case .amountValidationError(let rangeError):
            presentAmountValidationError(rangeError)
        }
    }
    
    func presentAmountValidationSuccess() {
        view.displayAmountValidationSuccess()
    }
    
    func presentPaymentAuthorization(value: Amount.Value) {
        view.displayPaymentAuthorization(value: value)
    }
    
    func presentPOCFStateChange(hidden: Bool) {
        hidden
        ? view.hidePOCF()
        : view.displayPOCF(message: POCFTextsFactory.makeMessage())
    }
}

private extension MakeDepositPresenter {
    func presentAmountParsingError(_ error: AmountValueTextParsingError) {
        switch error {
        case .negativeValue:
            view.displayAmountValidationFailure(with: "amount.parser.negativeValue".localized())
        case .invalidNumber:
            view.displayAmountValidationFailure(with: "amount.parser.invalidNumber".localized())
        }
    }

    func presentAmountValidationError(_ error: AmountValidatorError) {
        switch error {
        case .belowMinAmount(let amount):
            do {
                let message = String.localizedStringWithFormat("amount.validator.belowMinimum %@".localized(), try errorAmountFormatter.format(amount: amount))
                view.displayAmountValidationFailure(with: message)
            } catch let formattingError {
                Logger.warning("Presenting amount \"\(amount)\" failed with an error: \"\(formattingError)\"")
                view.displayAmountValidationFailure(with: "amount.validator.belowMinimum".localized())
            }
        case .aboveMaxAmount(let amount):
            do {
                let message = String.localizedStringWithFormat("amount.validator.aboveMaximum %@".localized(), try errorAmountFormatter.format(amount: amount))
                view.displayAmountValidationFailure(with: message)
            } catch let formattingError {
                Logger.warning("Presenting amount \"\(amount)\" failed with an error: \"\(formattingError)\"")
                view.displayAmountValidationFailure(with: "amount.validator.aboveMaximum".localized())
            }
        }
    }
}
