import Foundation
@testable import PaymentApp

extension CurrencyTable {
    static func makeFake(data: Data) -> CurrencyTable  {
        do {
            return try JSONDecoder().decode(CurrencyTable.self, from: data)
        } catch {
            return CurrencyTable.empty
        }
    }
}
