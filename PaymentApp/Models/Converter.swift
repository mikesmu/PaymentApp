import Foundation

func rounded(_ value: Double, decimalPlaces: Int) -> Double {
    let base = pow(10.0, Double(decimalPlaces))
    return round(base * value) / base
}

class Converter {
    private let table: CurrencyTable
    
    init(table: CurrencyTable) {
        self.table = table
    }
    
    func convert(_ amount: Double, of source: String, to target: String) -> Double? {
        guard source != target else { return amount }
        guard table.base == source else { return nil }
        guard let targetedRate = table.rates.first(where: { $0.currencyCode == target }) else { return nil }
        
        let decimalPart = pow(10.0, targetedRate.exponent) as NSNumber
        let result = Double(targetedRate.significand) * amount / Double(truncating: decimalPart)
        return rounded(result, decimalPlaces: 4)
    }
}

extension Converter {
    func validate(sourceCurrency: String, targetCurrency: String) -> Bool {
        return table.rates.filter { $0.currencyCode == sourceCurrency || $0.currencyCode == targetCurrency}.count == 2
    }
}
