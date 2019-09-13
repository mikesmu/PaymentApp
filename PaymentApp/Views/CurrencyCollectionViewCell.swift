import UIKit

protocol CurrencyCollectionViewCellDelegate: AnyObject {
    func didBeginEditing(cell: CurrencyCollectionViewCell, textField: UITextField)
    func didEnterAmount(amountString: String, cell: CurrencyCollectionViewCell)
}

class CurrencyCollectionViewCell: UICollectionViewCell {
    static let id: String = "CurrencyCollectionViewCell"
    
    @IBOutlet private weak var flagLabel: UILabel!
    @IBOutlet private weak var shortNameLabel: UILabel!
    @IBOutlet private weak var longNameLabel: UILabel!
    @IBOutlet private weak var textField: UITextField!
    
    weak var delegate: CurrencyCollectionViewCellDelegate?
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        textField.delegate = self
        textField.attributedPlaceholder = NSAttributedString(string: "0.0",
                                                             attributes: [
                                                                .font: UIFont.systemFont(ofSize: 18.0),
                                                                .foregroundColor: UIColor.lightGray
            ])
    }
    
    func display(rate: Rate) {
        shortNameLabel.text = rate.currencyCode
        longNameLabel.text = rate.currencyFullName
        flagLabel.text = CurrencyCodeToFlagMapper().flagEmoji(from: rate.currencyCode)
    }
    
    func display(amount: Double) {
        textField.text = amount != 0.0 ? "\(amount)" : nil
    }
}

extension CurrencyCollectionViewCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.didBeginEditing(cell: self, textField: textField)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let finalString = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        defer { delegate?.didEnterAmount(amountString: finalString, cell: self) }
        return true
    }
}

