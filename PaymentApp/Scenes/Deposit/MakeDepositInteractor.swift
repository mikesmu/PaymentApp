

protocol MakeDepositBusinessLogic {
    func validateAmount(text: String) -> Bool
    func updateAmount(from text: String)
    func formatAmount()
    func increaseAmountValue(by value: Amount.Value)
    func submitPayment()
    func showMultiplePaymentMethods()
    func handlePOCF()
    func beginEditingAmount()
    func endEditing(amountText: String?)
}

enum MakeDepositBusinessLogicError: Error, Equatable {
    case amountParsingError(AmountValueTextParsingError)
    case amountValidationError(AmountValidatorError)
}

class MakeDepositInteractor {
    let presenter: MakeDepositPresentationLogic
    private let amountValidator: AmountValidator
    private let amountValueTextParser: AmountValueTextParser
    private let amountValueTextValidator: AmountValueTextValidator
    private let pesProvider: PESProvider
    private var amount: Amount
    private var shouldPresentPOCF: Bool
    private let analyticsService: MakeDepositAnalyticsService
    
    init(presenter: MakeDepositPresentationLogic,
         amountValidator: AmountValidator,
         amountValueTextParser: AmountValueTextParser,
         amountValueTextValidator: AmountValueTextValidator,
         pesProvider: PESProvider,
         initialAmount: Amount,
         shouldPresentPOCF: Bool,
         analyticsService: MakeDepositAnalyticsService) {
        self.presenter = presenter
        self.amountValidator = amountValidator
        self.amountValueTextValidator = amountValueTextValidator
        self.amountValueTextParser = amountValueTextParser
        self.pesProvider = pesProvider
        self.amount = initialAmount
        self.shouldPresentPOCF = shouldPresentPOCF
        self.analyticsService = analyticsService
    }
}

extension MakeDepositInteractor: MakeDepositBusinessLogic {
    func validateAmount(text: String) -> Bool {
        return amountValueTextValidator.validate(text: text)
    }
    
    func updateAmount(from text: String) {
        switch amountValueTextParser.parse(text: text) {
        case .success(let value):
            Logger.debug("Text \"\(text)\" passed numeric validation successfully with output: \(value)")
            updateAmountValue(with: value)
            validateCurrentAmount()
        case .failure(let error):
            Logger.debug("Text \"\(text)\" failed to pass numeric validation with error: \(error)")
            presenter.present(validationError: .amountParsingError(error))
        }
    }
    
    func formatAmount() {
        presenter.present(amount: amount)
    }
    
    func increaseAmountValue(by value: Amount.Value) {
        analyticsService.track(event: .amountIncreased(increment: value))
        updateAmountValue(with: amount.value + value)
        validateCurrentAmount()
        formatAmount()
    }
    
    func submitPayment() {
        if let validationError = amountValidator.validate(amount: amount).error {
            Logger.warning("Deposit amount \"\(amount.value)\" failed validation with error: \(validationError)")
            presenter.present(validationError: MakeDepositBusinessLogicError.amountValidationError(validationError))
            return
        }
        analyticsService.track(event: .pay)
        presenter.presentPaymentAuthorization(value: amount.value)
    }
    
    func showMultiplePaymentMethods() {
        analyticsService.track(event: .multiplePaymentMethods)
        pesProvider.state = .notPreferred
        presenter.presentMultiplePaymentMethods()
    }
    
    func handlePOCF() {
        presenter.presentPOCFStateChange(hidden: !shouldPresentPOCF)
    }
    
    func beginEditingAmount() {
        analyticsService.track(event: .startAmountEditting)
    }
    
    func endEditing(amountText: String?) {
        guard let amountText = amountText, !amountText.isEmpty else {
            presenter.present(amount: nil)
            return
        }
        
        formatAmount()
        updateAmount(from: amountText)
    }
}

private extension MakeDepositInteractor {
    func updateAmountValue(with newValue: Amount.Value) {
        amount = Amount(value: newValue, currency: amount.currency)
    }
    
    func validateCurrentAmount() {
        switch amountValidator.validate(amount: amount) {
        case .success:
            presenter.presentAmountValidationSuccess()
            Logger.debug("Numeric amount \"\(amount.value)\" passed validation.")
        case .failure(let error):
            presenter.present(validationError: .amountValidationError(error))
            Logger.debug("Numeric amount \"\(amount.value)\" failed validation with error: \(error)")
        }
    }
}
