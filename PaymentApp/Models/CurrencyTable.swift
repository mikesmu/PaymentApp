//
//  CurrencyTable.swift
//  RevolutTest
//
//  Created by Michał Smulski on 23/01/2019.
//  Copyright © 2019 Michał Smulski. All rights reserved.
//

import Foundation

struct CurrencyTable: Codable, Equatable {
    enum Error: Swift.Error {
        case invalidDateFormat
    }
    
    var base: String
    var updatedAt: Date
    var rates: [Rate]
    
    enum CodingKeys: String, CodingKey {
        case base
        case updatedAt = "date"
        case rates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        base = try container.decode(String.self, forKey: .base)
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()
        guard let updatedAt = dateFormatter.date(from: try container.decode(String.self, forKey: .updatedAt)) else {
            throw Error.invalidDateFormat
        }
        self.updatedAt = updatedAt
        
        let ratesDict = try container.decode([String: Double].self, forKey: .rates)
        rates = ratesDict.map { Rate(currencySymbol: $0.key, value: $0.value) }
    }
    
    public init(base: String, updatedAt: Date = .init(), rates: [Rate]) {
        self.base = base
        self.updatedAt = updatedAt
        self.rates = rates
    }
}
