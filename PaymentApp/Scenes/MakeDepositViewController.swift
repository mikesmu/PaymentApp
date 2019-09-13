import UIKit
import PassKit

protocol MakeDepositViewLogic: class {
    func display(formattedAmountValue: String?)
    func displayAmountValidationFailure(with text: String)
    func displayAmountValidationSuccess()
    func displayPaymentAuthorization(value: Amount.Value)
}

class DepositViewController: UIViewController {
    var interactor: MakeDepositBusinessLogic!
    var router: MakeDepositRoutingLogic!
    
    @IBOutlet private weak var validationStatusImageView: UIImageView!
    @IBOutlet private var amountSectionHeighConstraint: NSLayoutConstraint!
    @IBOutlet private var mainStackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var amountUnderlineView: UIView!
    @IBOutlet private weak var amountTextField: UITextField!
    @IBOutlet private weak var amountErrorLabel: UILabel!
    @IBOutlet private weak var amountBackgroundView: UIView!
    @IBOutlet private weak var errorView: UIStackView!
    @IBOutlet private weak var depositSectionTitleLabel: UILabel!
    @IBOutlet private weak var depositSectionSubtitleLabel: UILabel!
    @IBOutlet private var closingKeyboardGestureRecognizers: [UIGestureRecognizer]!
    @IBOutlet private weak var actionButtonsStackView: UIStackView!
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
    private lazy var mainStackViewCenterYConstraint: NSLayoutConstraint = {
        return mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    }()
    
    init() {
        super.init(nibName: String(describing: DepositViewController.self),
                   bundle: .main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        amountTextField.setupDoneButtonInputAccessoryView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldTextDidChangeNotification(_:)), name: UITextField.textDidChangeNotification, object: amountTextField)
        
        styleUserInterfaceElements()
        setupPayButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keyboardWorker.startObserving()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardWorker.stopObserving()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension DepositViewController: KeyboardNotificationServiceDelegate {
    func keyboardWillShow(service: KeyboardNotificationService, frame: CGRect) {
        traitCollection.userInterfaceIdiom == .pad ? handleVisibleKeyboardOnIpad() : handleVisibleKeyboardOnIphone(keyboardFrame: frame)
    }
    
    func keyboardWillHide(service: KeyboardNotificationService, frame: CGRect) {
        guard traitCollection.userInterfaceIdiom != .pad else { return }
        
        UIView.animate(withDuration: CATransaction.animationDuration(), animations: { self.view.layoutIfNeeded() })
    }
    
    func keyboardDidHide(service: KeyboardNotificationService, frame: CGRect) {
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

extension DepositViewController: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        // if that set ivar is not nil, show summary
        dismiss(animated: true, completion: nil)
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        // set some value in ivar
        completion(.success)
    }
}

extension DepositViewController: MakeDepositViewLogic {
    func displayPaymentAuthorization(value: Amount.Value) {
        do {
            let configuration = try ApplePayPaymentConfiguration(itemLabel: "Couple of socks",
                                                             currencyCode: "GBP",
                                                             countryCode: "GB",
                                                             merchantIdentifier: "replacethisId",
                                                             supportedNetworks: [.visa, .masterCard],
                                                             merchantCapabilities: [.capabilityCredit, .capabilityDebit, .capability3DS])
            
            let request = PKPaymentRequest(amountValue: value, configuration: configuration)
            let viewController = PKPaymentAuthorizationViewController(paymentRequest: request)
            viewController?.delegate = self
            viewController.flatMap { present($0, animated: true, completion: nil) }
        } catch {
            print("catched an error while creating payment configuration \(error)")
        }
    }
    
    func display(formattedAmountValue: String?) {
        guard amountTextField.text != formattedAmountValue else { return }
        
        amountTextField.text = formattedAmountValue
        if (formattedAmountValue?.isEmpty ?? true) && errorView.isHidden {
            amountUnderlineView.isHidden = true
        }
    }
    
    func displayAmountValidationFailure(with text: String) {
        setPayButton(disabled: true)
        amountErrorLabel.text = text
        setErrorView(hidden: false)
        if #available(iOS 10.0, *) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        displayUnderlineView(backgroundColor: .red)
        validationFinished(withSuccess: false)
    }
    
    func displayAmountValidationSuccess() {
        setErrorView(hidden: true)
        setPayButton(disabled: false)
        displayUnderlineView(backgroundColor: .green)
        validationFinished(withSuccess: true)
    }
    
    func displayUnderlineView(backgroundColor: UIColor) {
        amountUnderlineView.backgroundColor = backgroundColor
        amountUnderlineView.isHidden = false
    }
    
    func validationFinished(withSuccess: Bool) {
        guard !amountTextField.isFirstResponder else { return }
        
        let bundle = Bundle(for: DepositViewController.self)
        validationStatusImageView.image = withSuccess
            ? UIImage(named: "ico_validation_success", in: bundle, compatibleWith: nil)
            : UIImage(named: "ico_validation_error", in: bundle, compatibleWith: nil)
        validationStatusImageView.isHidden = false
    }
}

extension DepositViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        interactor.beginEditingAmount()
        closingKeyboardGestureRecognizers.forEach { $0.isEnabled = true }
        validationStatusImageView.isHidden = true
        amountUnderlineView.isHidden = false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        let validationResult = interactor.validateAmount(text: text)
        return validationResult
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        interactor.endEditing(amountText: textField.text)
        closingKeyboardGestureRecognizers.forEach { $0.isEnabled = false }
    }
}

// MARK: IBActions
extension DepositViewController {
    @objc func textFieldTextDidChangeNotification(_ notification: Notification) {
        guard let textField = notification.object as? UITextField else {
            assertionFailure("The notification sender has to be a UITextField")
            return
        }
        
        interactor.updateAmount(from: textField.text ?? "")
    }
    
    @IBAction func payButtonTapped(_ sender: Any) {
        amountTextField.resignFirstResponder()
        interactor.submitPayment()
    }
    
    @IBAction func increaseAmountButtonTapped(_ sender: DepositAmountValueButton) {
        guard let amountToAdd = sender.amountValue else {
            assertionFailure("Tapping does not work becouse amount for button was not set.")
            return
        }
        interactor.increaseAmountValue(by: amountToAdd)
    }
    
    @IBAction func tapGestureAction(_ sender: Any) {
        amountTextField.resignFirstResponder()
    }
}

// MARK: UI styling and setup
private extension DepositViewController {
    func updateConstraints(pocfVisible: Bool) {
        mainStackViewTopConstraint.constant = 0.07 * view.frame.height
        amountSectionHeighConstraint.constant = 46.0
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
        view.backgroundColor = .white
        
        styleDepositSection()
        styleErrorSection()
        styleAmountSection()
        stylePayButton()
    }
    
    func setupCopies() {
        title = "deposit.title".localized()
        depositSectionTitleLabel.text = "deposit.header.title".localized()
        depositSectionSubtitleLabel.text = "deposit.header.subtitle".localized()
        amountTextField.placeholder = "deposit.textField.placeholder".localized()
    }
    
    func setupPayButton() {
        setPayButton(disabled: true)
        payButton.heightAnchor.constraint(equalToConstant: 46.0).isActive = true
        actionButtonsStackView.insertArrangedSubview(payButton, at: 0)
    }
    
    func styleDepositSection() {
        depositSectionTitleLabel.font = .systemFont(ofSize: 16.0)
        depositSectionTitleLabel.textColor = .black
        depositSectionSubtitleLabel.font = .systemFont(ofSize: 12.0)
        depositSectionSubtitleLabel.textColor = .black
    }
    
    func styleErrorSection() {
        amountErrorLabel.textColor = .red
        amountErrorLabel.font = .systemFont(ofSize: 10.0)
    }
    
    func styleAmountSection() {
        amountTextField.font = .systemFont(ofSize: 12.0)
        amountTextField.textColor = .black
        
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
    
    func setPayButton(disabled: Bool) {
        payButton.isEnabled = !disabled
        payButton.alpha = disabled ? 0.3 : 1.0
        payButton.accessibilityIdentifier = disabled ? "WHApplePay.Deposit.PayButton.Disabled" : "WHApplePay.Deposit.PayButton.Enabled"
    }
}
