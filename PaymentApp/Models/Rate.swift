//
//  Rate.swift
//  RevolutTest
//
//  Created by Michał Smulski on 23/01/2019.
//  Copyright © 2019 Michał Smulski. All rights reserved.
//

import Foundation

struct Rate: Codable, Equatable {
    var currencyCode: String
    var significand: Int
    private(set) var exponent: Int
    
    var currencyFullName: String {
        return Locale(identifier: currencyCode).localizedString(forCurrencyCode: currencyCode) ?? ""
    }
    
    init(currencySymbol: String, value: Double) {
        self.currencyCode = currencySymbol
        
        let parts = "\(value)".split(separator: ".")
        if parts.last == "0" {
            self.significand = Int(parts.first!)!
            self.exponent = 0
        } else {
            self.significand = Int(parts.joined())!
            self.exponent = parts.last!.count
        }
    }
}
