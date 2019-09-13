import XCTest
@testable import PaymentApp

class CurrenciesRepositoryTests: XCTestCase {
    var tested: CurrenciesRepository!
    
    override func setUp() {
        let fakeSession = URLSession(configuration: {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [FakeURLProtocol.self]
            return configuration
        }())
        let service = CurrenciesService(baseUrl: .dummy, session: fakeSession)
        tested = CurrenciesRepository(service: service)
    }
    
    func testReturnsValidData() {
        let data = Data.fake(base: "EUR")
        let fakeTable = CurrencyTable.makeFake(data: data)
        FakeURLProtocol.requestHandler = { _ in return (HTTPURLResponse(), data) }
        let testExpectation = expectation(description: "testReturnsValidData")
        
        tested.requestLatestTable(base: "EUR") { rates in
            // returned rates include base rate, hence +1
            XCTAssertEqual(rates.count, fakeTable.rates.count + 1)
            testExpectation.fulfill()
        }
        
        wait(for: [testExpectation], timeout: 1.0)
    }
    
    override func tearDown() {
        tested = nil
        FakeURLProtocol.requestHandler = nil
    }

}
