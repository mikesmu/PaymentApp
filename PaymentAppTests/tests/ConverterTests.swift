import XCTest
@testable import PaymentApp

extension CurrencyTable {
    static let empty = CurrencyTable(base: "", updatedAt: .init(), rates: [])
}

class ConverterTests: XCTestCase {
    var tested: Converter!
    
    override func tearDown() {
        tested = nil
    }
    
    func testSameCurrency() {
        let rates = [ Rate(currencySymbol: "GBP", value: 0.90234) ]
        let fakeTable = CurrencyTable(base: "EUR", rates: rates)
        tested = Converter(table: fakeTable)
        
        let expected = tested.convert(100, of: "GBP", to: "GBP")
        
        XCTAssertEqual(expected, 100)
    }
    
    func testConvertEURToGBPIntAmount() {
        let rates = [ Rate(currencySymbol: "GBP", value: 0.90234) ]
        let fakeTable = CurrencyTable(base: "EUR", rates: rates)
        tested = Converter(table: fakeTable)
        
        let expected = tested.convert(100, of: "EUR", to: "GBP")
        
        XCTAssertEqual(expected, 90.234)
    }
    
    func testConvertEUR2GBPDoubleAmount() {
        let rates = [ Rate(currencySymbol: "PLN", value: 4.3395) ]
        let fakeTable = CurrencyTable(base: "EUR", rates: rates)
        tested = Converter(table: fakeTable)
        
        let expected = tested.convert(9.34, of: "EUR", to: "PLN")
        
        XCTAssertEqual(expected, 40.5309)
    }
    
    func testConvertDifferentBase() {
        let rates = [ Rate(currencySymbol: "PLN", value: 4.29),
                      Rate(currencySymbol: "USD", value: 1.14) ]
        let fakeTable = CurrencyTable(base: "EUR", rates: rates)
        tested = Converter(table: fakeTable)
        
        let expected = tested.convert(100, of: "PLN", to: "USD")
        
        XCTAssertEqual(expected, nil)
    }
    
    func testEmptyListing() {
        tested = Converter(table: .empty)
        
        let expected = tested.convert(100, of: "EUR", to: "some_currency")
        
        XCTAssertNil(expected)
    }
    
    func testTargetCurrencyNotFound() {
        let fakeTable = CurrencyTable(base: "EUR", rates: [])
        tested = Converter(table: fakeTable)
        
        XCTAssertNil(tested.convert(100, of: "EUR", to: "currency_you_will_not_find"))
    }
    
    func testBaseCurrencyNotFound() {
        let fakeTable = CurrencyTable(base: "currency_you_will_not_find", rates: [])
        tested = Converter(table: fakeTable)
        
        XCTAssertNil(tested.convert(100, of: "EUR", to: "some_currency"))
    }
    
}
