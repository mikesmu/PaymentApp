import XCTest
@testable import PaymentApp

extension Bundle {
    static let test = Bundle(for: CurrenciesServiceTests.self)
}
extension CurrenciesServiceTests {
    enum Error: Swift.Error {
        case dummy
    }
}

class CurrenciesServiceTests: XCTestCase {
    var tested: CurrenciesService!
    
    override func setUp() {
        let fakeSession = URLSession(configuration: {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [FakeURLProtocol.self]
            return configuration
        }())
        tested = CurrenciesService(baseUrl: .dummy, session: fakeSession)
    }
    
    override func tearDown() {
        tested = nil
        FakeURLProtocol.requestHandler = nil
    }
    
    func testValidData() {
        let data = Data.fake(base: "EUR")
        let fakeTable = CurrencyTable.makeFake(data: data)
        FakeURLProtocol.requestHandler = { _ in return (HTTPURLResponse(), data) }
        let testExpectation = expectation(description: "testValidData")
        
        tested.latestTable(base: "EUR", completion: { result in
            switch result {
            case .error(let error):
                XCTFail("expected to get data, but got error \(error)")
            case .success(let payload):
                XCTAssertEqual(payload, fakeTable)
            }
            testExpectation.fulfill()
        })
        wait(for: [testExpectation], timeout: 1.0)
    }
    
    func testNilData() {
        FakeURLProtocol.requestHandler = { _ in return (HTTPURLResponse(), nil) }
        let testExpectation = expectation(description: "testNilData")
        
        tested.latestTable(base: "dummy_base", completion: { result in
            switch result {
            case .error(let error):
                XCTAssertTrue(error is CurrenciesService.Error)
            case .success(_):
                XCTFail("expected to get error, instead got data")
            }
            testExpectation.fulfill()
        })
        wait(for: [testExpectation], timeout: 1.0)
    }
    
    func testRandomData() {
        FakeURLProtocol.requestHandler = { _ in return (HTTPURLResponse(), Data.random()) }
        let testExpectation = expectation(description: "testRandomData")
        
        tested.latestTable(base: "dummy_base", completion: { result in
            switch result {
            case .error(let error):
                XCTAssertTrue(error is DecodingError)
            case .success(_):
                XCTFail("expected to get error, instead got data")
            }
            testExpectation.fulfill()
        })
        wait(for: [testExpectation], timeout: 1.0)
    }
    
    func testError() {
        let testExpectation = expectation(description: "testValidData")
        FakeURLProtocol.requestHandler = { _ in throw Error.dummy }
        
        tested.latestTable(base: "dummy_base") { result in
            switch result {
            case .success(_):
                XCTFail("expected error, got valid data")
            case .error(let error):
                XCTAssertTrue(error is CurrenciesServiceTests.Error)
            }
            testExpectation.fulfill()
        }
        wait(for: [testExpectation], timeout: 1.0)
    }
    
}
