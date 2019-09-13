

import UIKit
import PassKit

protocol MakeDepositViewLogic: class {
    func displayMultiplePaymentMethods()
    func display(formattedAmountValue: String?)
    func displayAmountValidationFailure(with text: String)
    func displayAmountValidationSuccess()
    func displayPaymentAuthorization(value: Amount.Value)
    func displayPOCF(message: NSAttributedString)
    func hidePOCF()
}

class MakeDepositViewController: UIViewController {
    var interactor: MakeDepositBusinessLogic!
    var router: MakeDepositRoutingLogic!
    
    @IBOutlet private weak var validationStatusImageView: UIImageView!
    @IBOutlet private var headerImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var amountSectionHeighConstraint: NSLayoutConstraint!
    @IBOutlet private var buttonsHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var mainStackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var amountUnderlineView: UIView!
    @IBOutlet private weak var amountTextField: UITextField!
    @IBOutlet private weak var amountErrorLabel: UILabel!
    @IBOutlet private weak var amountBackgroundView: UIView!
    @IBOutlet private weak var errorView: UIStackView!
    @IBOutlet private weak var depositSectionTitleLabel: UILabel!
    @IBOutlet private weak var depositSectionSubtitleLabel: UILabel!
    @IBOutlet private var quickDepositButtons: [DepositAmountValueButton]!
    @IBOutlet private var separators: [UIView]!
    @IBOutlet private weak var multiplePaymentsButton: UIButton!
    @IBOutlet private weak var multiplePaymentsLabel: UILabel!
    @IBOutlet private var closingKeyboardGestureRecognizers: [UIGestureRecognizer]!
    @IBOutlet private weak var actionButtonsStackView: UIStackView!
    @IBOutlet private weak var pocfTextView: UITextView!
    @IBOutlet private weak var pocfStackView: UIStackView!
    @IBOutlet private weak var mainStackView: UIStackView!
    private lazy var payButton: PKPaymentButton = {
        let button = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .black)
        button.addTarget(self, action: #selector(payButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var keyboardWorker: KeyboardNotificationService = {
        let worker = KeyboardNotificationService()
        worker.delegate = self
        return worker
    }()
    private var popoverDelegateProxy: UIPopoverPresentationControllerDelegateProxy?
    private lazy var mainStackViewCenterYConstraint: NSLayoutConstraint = {
        return mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        amountTextField.setupDoneButtonInputAccessoryView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldTextDidChangeNotification(_:)), name: UITextField.textDidChangeNotification, object: amountTextField)
        
        styleUserInterfaceElements()
        setupPayButton()
        setupQuickDepositButtons()
        setupCancelNavigationButton(action: #selector(cancelButtonTapped(_:)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        interactor.handlePOCF()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keyboardWorker.startObserving()
        setupPopoverProxyDelegate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardWorker.stopObserving()
        tearDownPopoverProxyDelegate()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension MakeDepositViewController: KeyboardNotificationServiceDelegate {
    func keyboardWillShow(service: KeyboardNotificationService, frame: CGRect) {
        Logger.verbose("Keyboard will show in \(self)")
        traitCollection.userInterfaceIdiom == .pad ? handleVisibleKeyboardOnIpad() : handleVisibleKeyboardOnIphone(keyboardFrame: frame)
    }
    
    func keyboardWillHide(service: KeyboardNotificationService, frame: CGRect) {
        Logger.verbose("Keyboard will hide in \(self)")
        guard traitCollection.userInterfaceIdiom != .pad else { return }
        
        interactor.handlePOCF()
        UIView.animate(withDuration: CATransaction.animationDuration(), animations: { self.view.layoutIfNeeded() })
    }
    
    func keyboardDidHide(service: KeyboardNotificationService, frame: CGRect) {
        Logger.verbose("Keyboard did hide in \(self)")
        guard traitCollection.userInterfaceIdiom == .pad else { return }
        
        mainStackViewCenterYConstraint.isActive = false
        mainStackViewTopConstraint.isActive = true
        UIView.animate(withDuration: CATransaction.animationDuration(), animations: { self.view.layoutIfNeeded() })
    }
    
    private func payButtonToViewDistance() -> CGFloat {
        return view.frame.height - mainStackView.frame.maxY + actionButtonsStackView.frame.height - payButton.frame.height - 8.0
    }
    
    private func handleVisibleKeyboardOnIphone(keyboardFrame: CGRect) {
        let distance = payButtonToViewDistance()
        if distance < keyboardFrame.height {
            // not enough space to display keyboard
            mainStackViewTopConstraint.constant -= keyboardFrame.height - distance
            UIView.animate(withDuration: CATransaction.animationDuration(), animations: { self.view.layoutIfNeeded() })
        }
    }
    
    private func handleVisibleKeyboardOnIpad() {
        mainStackViewTopConstraint.isActive = false
        mainStackViewCenterYConstraint.isActive = true
        UIView.animate(withDuration: CATransaction.animationDuration(), animations: { self.view.layoutIfNeeded() })
    }
}

extension MakeDepositViewController: MakeDepositViewLogic {
    func displayPaymentAuthorization(value: Amount.Value) {
        do {
            try router.routeToPayment(value: value)
        } catch let error as MakeDepositRoutingError {
            Logger.error("Routing to payment failed with error: \(error)")
            // TODO: Check what TODO
        } catch let error {
            Logger.error("Routing to payment failed with error: \(error)")
            // TODO: 🤔
        }
    }
    
    func display(formattedAmountValue: String?) {
        guard amountTextField.text != formattedAmountValue else { return }
        
        amountTextField.text = formattedAmountValue
        if (formattedAmountValue?.isEmpty ?? true) && errorView.isHidden {
            amountUnderlineView.isHidden = true
        }
    }
    
    func displayMultiplePaymentMethods() {
        router.routeToMultiplePaymentMethods()
    }
    
    func displayAmountValidationFailure(with text: String) {
        setPayButton(disabled: true)
        amountErrorLabel.text = text
        setErrorView(hidden: false)
        if #available(iOS 10.0, *) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        displayUnderlineView(backgroundColor: .whError)
        validationFinished(withSuccess: false)
    }
    
    func displayAmountValidationSuccess() {
        setErrorView(hidden: true)
        setPayButton(disabled: false)
        displayUnderlineView(backgroundColor: .whSuccess)
        validationFinished(withSuccess: true)
    }
    
    func displayUnderlineView(backgroundColor: UIColor) {
        amountUnderlineView.backgroundColor = backgroundColor
        amountUnderlineView.isHidden = false
    }
    
    func displayPOCF(message: NSAttributedString) {
        pocfTextView.attributedText = message
        pocfTextView.tintColor = .whPrimary
        pocfTextView.linkTextAttributes = [
            .foregroundColor: UIColor.whPrimary
        ]
        pocfTextView.textAlignment = .center
        stylePOCFTextView()
        pocfStackView.isHidden = false
        updateConstraints(pocfVisible: true)
    }
    
    func hidePOCF() {
        pocfStackView.isHidden = true
        updateConstraints(pocfVisible: false)
    }
    
    func validationFinished(withSuccess: Bool) {
        guard !amountTextField.isFirstResponder else { return }
        
        let bundle = Bundle(for: MakeDepositViewController.self)
        validationStatusImageView.image = withSuccess
            ? UIImage(named: "ico_validation_success", in: bundle, compatibleWith: nil)
            : UIImage(named: "ico_validation_error", in: bundle, compatibleWith: nil)
        validationStatusImageView.isHidden = false
    }
}

extension MakeDepositViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        Logger.verbose("Amount textfield did begin editing")
        interactor.beginEditingAmount()
        closingKeyboardGestureRecognizers.forEach { $0.isEnabled = true }
        validationStatusImageView.isHidden = true
        amountUnderlineView.isHidden = false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        let validationResult = interactor.validateAmount(text: text)
        Logger.verbose("Amount textfield text changed to \"\(text)\". Accepted? : [\(validationResult)]")
        return validationResult
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        Logger.verbose("Amount textfield did end editing")
        interactor.endEditing(amountText: textField.text)
        closingKeyboardGestureRecognizers.forEach { $0.isEnabled = false }
    }
}

// MARK: IBActions
extension MakeDepositViewController {
    @objc func textFieldTextDidChangeNotification(_ notification: Notification) {
        guard let textField = notification.object as? UITextField else {
            assertionFailure("The notification sender has to be a UITextField")
            return
        }
        
        interactor.updateAmount(from: textField.text ?? "")
    }
    
    @IBAction func payButtonTapped(_ sender: Any) {
        Logger.debug("Pay button was tapped with payment value: \"\(amountTextField.text ?? "")\"")
        amountTextField.resignFirstResponder()
        interactor.submitPayment()
    }
    
    @IBAction func multiplePaymentMethodsButtonTapped(_ sender: Any) {
        Logger.debug("Multiple Payment Methds button was tapped in \(self)")
        interactor.showMultiplePaymentMethods()
    }
    
    @IBAction func increaseAmountButtonTapped(_ sender: DepositAmountValueButton) {
        guard let amountToAdd = sender.amountValue else {
            assertionFailure("Tapping does not work becouse amount for button was not set.")
            return
        }
        Logger.debug("Amount Pre-select button with value \"\(amountToAdd)\" was tapped")
        interactor.increaseAmountValue(by: amountToAdd)
    }
    
    @IBAction func tapGestureAction(_ sender: Any) {
        amountTextField.resignFirstResponder()
    }
    
    @objc func cancelButtonTapped(_ sender: Any) {
        router.routeToApplication()
    }
}

// MARK: UI styling and setup
private extension MakeDepositViewController {
    func updateConstraints(pocfVisible: Bool) {
        if pocfVisible {
            mainStackViewTopConstraint.constant = 0.06 * view.frame.height
            amountSectionHeighConstraint.constant = 40.0
            buttonsHeightConstraint.constant = 40.0
        } else {
            mainStackViewTopConstraint.constant = 0.07 * view.frame.height
            amountSectionHeighConstraint.constant = 46.0
            buttonsHeightConstraint.constant = 46.0
        }
        headerImageHeightConstraint.constant = min(68.0, 0.088 * view.frame.height)
        view.layoutIfNeeded()
    }
    
    func setErrorView(hidden: Bool) {
        guard errorView.isHidden != hidden else {
            return
        }
        UIView.animate(withDuration: CATransaction.animationDuration()) {
            self.errorView.isHidden = hidden
        }
    }
    
    func styleUserInterfaceElements() {
        setupCopies()
        view.backgroundColor = .whWhite
        
        styleDepositSection()
        styleQuickDepositButtons()
        styleErrorSection()
        styleAmountSection()
        stylePayButton()
        styleSeparator()
        styleMultiplePaymentsButton()
    }
    
    func setupCopies() {
        title = "deposit.title".localized()
        depositSectionTitleLabel.text = "deposit.header.title".localized()
        depositSectionSubtitleLabel.text = "deposit.header.subtitle".localized()
        multiplePaymentsLabel.text = "deposit.separator.title".localized()
        amountTextField.placeholder = "deposit.textField.placeholder".localized()
    }
    
    func stylePOCFTextView() {
        pocfTextView.tintColor = .bermudaGray
    }
    
    func setupPayButton() {
        setPayButton(disabled: true)
        payButton.heightAnchor.constraint(equalToConstant: 46.0).isActive = true
        actionButtonsStackView.insertArrangedSubview(payButton, at: 0)
    }
    
    var quickDepositValueSequence: AnySequence<Amount.Value> {
        return AnySequence<Amount.Value> { () -> AnyIterator<Amount.Value> in
            var value: Amount.Value = 25
            return AnyIterator<Amount.Value> {
                defer { value *= 2 }
                return value
            }
        }
    }
    
    func setupQuickDepositButtons() {
        let sorted = quickDepositButtons.sorted { $0.tag < $1.tag }
        zip(sorted, quickDepositValueSequence).forEach { button, value in
            button.amountValue = value
            button.setTitle("+\(Int(value))", for: .normal)
        }
    }
    
    func styleDepositSection() {
        depositSectionTitleLabel.font = .regularVerdanaFont(ofSize: 16.0)
        depositSectionTitleLabel.textColor = .whPrimary
        depositSectionSubtitleLabel.font = .regularVerdanaFont(ofSize: 12.0)
        depositSectionSubtitleLabel.textColor = .bermudaGray
    }
    
    func styleQuickDepositButtons() {
        quickDepositButtons.forEach { $0.applyLightStyle() }
    }
    
    func styleErrorSection() {
        amountErrorLabel.textColor = .whError
        amountErrorLabel.font = .regularVerdanaFont(ofSize: 10.0)
    }
    
    func styleAmountSection() {
        amountTextField.font = .regularVerdanaFont(ofSize: 12.0)
        amountTextField.textColor = .whPrimary
        
        amountBackgroundView.superview?.layer.cornerRadius = 2.0
        amountBackgroundView.layer.cornerRadius = 2.0
        amountBackgroundView.layer.borderColor = UIColor.cornflowerBlue.cgColor
        amountBackgroundView.layer.borderWidth = 1.0
        
        amountUnderlineView.backgroundColor = .cornflowerBlue
    }
    
    func stylePayButton() {
        payButton.layer.cornerRadius = 4.0
        payButton.clipsToBounds = true
    }
    
    func styleMultiplePaymentsButton() {
        multiplePaymentsLabel.textColor = .shipCove
        multiplePaymentsLabel.font = .regularVerdanaFont(ofSize: 12.0)
        
        multiplePaymentsButton.titleLabel?.numberOfLines = 0
        multiplePaymentsButton.titleLabel?.textAlignment = .center
        [UIControl.State.normal, .highlighted].forEach {
            let title = NSAttributedString(string: "deposit.mmpmButton.title".localized(), attributes: [
                .font: UIFont.regularVerdanaFont(ofSize: 12.0),
                .foregroundColor: UIColor.whPrimary
                ])
            multiplePaymentsButton.setAttributedTitle(title, for: $0)
        }
    }
    
    func styleSeparator() {
        separators.forEach { $0.backgroundColor = .glitter }
    }
    
    func setPayButton(disabled: Bool) {
        payButton.isEnabled = !disabled
        payButton.alpha = disabled ? 0.3 : 1.0
        payButton.accessibilityIdentifier = disabled ? "WHApplePay.Deposit.PayButton.Disabled" : "WHApplePay.Deposit.PayButton.Enabled"
    }
    
    func setupPopoverProxyDelegate() {
        guard let popoverPresentationController = popoverPresentationController else { return }
        let delegates = [self, popoverPresentationController.delegate].compactMap { $0 }
        popoverDelegateProxy = UIPopoverPresentationControllerDelegateProxy(delegates: delegates)
        popoverPresentationController.delegate = popoverDelegateProxy
    }
    
    func tearDownPopoverProxyDelegate() {
        guard let popoverPresentationController = popoverPresentationController else { return }
        popoverPresentationController.delegate = popoverDelegateProxy?.delegates.allObjects.first { $0 !== self }
        popoverDelegateProxy = nil
    }
}

extension MakeDepositViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        if amountTextField.isFirstResponder {
            amountTextField.resignFirstResponder()
            return false
        } else {
            return true
        }
    }
}

extension MakeDepositViewController: Trackable {
    var trackIdentifier: String? {
        return "MakeApplePayDeposit"
    }
}
