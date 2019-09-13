import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let repository = CurrenciesRepository(service: CurrenciesService(baseUrl: URL(string: "https://api.exchangeratesapi.io")!))
    private var rates: [Rate] = []
    private let baseIndexPath = IndexPath(row: 0, section: 0)
    private var baseRate: Rate? {
        guard baseIndexPath.row < rates.count else { return nil }
        return rates[baseIndexPath.row]
    }
    private var baseAmount: Double = 100
    private var baseCurrency: String {
        return baseRate?.currencyCode ?? "GBP"
    }
    private lazy var refreshTimer = Timer(deadline: DispatchTime.now() + 2.0, repeatingInterval: 2.0) { [weak self] in
        self?.refreshCurrenciesTable() {
            self?.reloadTableView(startIndex: 1)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Converter"
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 190.0, height: 100.0)
        layout.minimumInteritemSpacing = 10.0
        layout.minimumLineSpacing = 10.0
        layout.sectionInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        
        collectionView.register(UINib(nibName: CurrencyCollectionViewCell.id, bundle: .main),
                                forCellWithReuseIdentifier: CurrencyCollectionViewCell.id)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = layout
        collectionView.keyboardDismissMode = .onDrag
        
        refreshCurrenciesTable() {
            self.collectionView.reloadData()
            self.refreshTimer.start()
        }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    private func update(_ cell: CurrencyCollectionViewCell, withRate rate: Rate) {
        cell.display(rate: rate)
        cell.delegate = self
        cell.display(amount: repository.convert(baseAmount, of: baseCurrency, to: rate.currencyCode))
    }
    
    private func update(_ cell: CurrencyCollectionViewCell, at indexPath: IndexPath) {
        let rate = rates[indexPath.row]
        update(cell, withRate: rate)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CurrencyCollectionViewCell.id,
                                                      for: indexPath) as! CurrencyCollectionViewCell
        update(cell, at: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rates.count
    }
}

extension ViewController: CurrencyCollectionViewCellDelegate {
    func didEnterAmount(amountString: String, cell: CurrencyCollectionViewCell) {
        updateBaseAmount(to: amountString)
        reloadTableView(startIndex: 1)
    }
    
    fileprivate func moveEditedCellToTop(cellIndexPath indexPath: IndexPath) {
        let rateToMove = rates[indexPath.row]
        rates.remove(at: indexPath.row)
        rates.insert(rateToMove, at: baseIndexPath.row)
        collectionView.moveItem(at: indexPath, to: baseIndexPath)
    }
    
    func didBeginEditing(cell: CurrencyCollectionViewCell, textField: UITextField) {
        guard let indexPath = collectionView.indexPath(for: cell), indexPath != baseIndexPath else { return }
        
        self.refreshTimer.suspend()
        updateBaseAmount(to: textField.text ?? "")
        
        collectionView.performBatchUpdates({
            moveEditedCellToTop(cellIndexPath: indexPath)
        }, completion: { finished in
            self.refreshCurrenciesTable() {
                self.reloadTableView()
                self.refreshTimer.start()
            }
        })
    }
}

private extension ViewController {
    func refreshCurrenciesTable(completion: (() -> Void)? = nil) {
        repository.requestLatestTable(base: baseCurrency) { [weak self] rates in
            guard let `self` = self else { return }
            
            DispatchQueue.main.async {
                // TODO: sort new rates to match order of previous one
                self.rates = rates
                completion?()
            }
        }
    }
    
    func reloadTableView(startIndex: Int = 0) {
        (startIndex...collectionView.numberOfItems(inSection: baseIndexPath.section))
            .map { IndexPath(row: $0, section: baseIndexPath.section) }
            .reduce([], { (accum, elem) -> [(cell: CurrencyCollectionViewCell, indexPath: IndexPath)] in
                guard let cell = collectionView.cellForItem(at: elem) as? CurrencyCollectionViewCell else {
                    return accum
                }
                var accumCopy = accum
                accumCopy.append((cell, elem))
                return accumCopy
            })
            .forEach { pair in
                self.update(pair.cell, at: pair.indexPath)
        }
    }
    
    func updateBaseAmount(to amountString: String) {
        self.baseAmount = Double(amountString) ?? 0.0
    }
}
