import XCTest
@testable import PaymentApp

class RateTests: XCTestCase {
    var tested: Rate!

    override func tearDown() {
        tested = nil
    }
    
    func testZero() {
        tested = Rate(currencySymbol: "", value: 0)
        
        XCTAssertEqual(tested.significand, 0)
        XCTAssertEqual(tested.exponent, 0)
    }

    func testNoDecimalPlaces() {
        tested = Rate(currencySymbol: "", value: 123)
        
        XCTAssertEqual(tested.significand, 123)
        XCTAssertEqual(tested.exponent, 0)
    }
    
    func testSingleDecimalPlace() {
        tested = Rate(currencySymbol: "", value: 123.1)
        
        XCTAssertEqual(tested.significand, 1231)
        XCTAssertEqual(tested.exponent, 1)
    }
    
    func testNoSignificand() {
        tested = Rate(currencySymbol: "", value: 0.912323)
        
        XCTAssertEqual(tested.significand, 912323)
        XCTAssertEqual(tested.exponent, 6)
    }
    
    func testDecimalPlaceWithTrailingZero() {
        tested = Rate(currencySymbol: "", value: 123.120)
        
        XCTAssertEqual(tested.significand, 12312)
        XCTAssertEqual(tested.exponent, 2)
    }
}
