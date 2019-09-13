import Foundation

extension Data {
    static func fake(base: String) -> Data {
        guard let path = Bundle.test.path(forResource: "table_\(base)_base", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                return Data()
        }
        return data
    }
    
    static func random() -> Data {
        return "some_random_string".data(using: .utf8)!
    }
}
