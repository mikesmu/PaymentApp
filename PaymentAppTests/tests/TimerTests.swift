import XCTest
@testable import PaymentApp

class TimerTests: XCTestCase {
    var tested: PaymentApp.Timer!

    override func tearDown() {
       tested = nil
    }

    func testNonRepeating() {
        let expectaction = expectation(description: "testNonRepeating")
        tested = PaymentApp.Timer(deadline: DispatchTime.now(), repeatingInterval: .infinity) { expectaction.fulfill() }
        
        tested.start()
        
        wait(for: [expectaction], timeout: 1.0)
    }
}
