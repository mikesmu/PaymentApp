//
//  CurrenciesRepository.swift
//  RevolutTest
//
//  Created by Michał Smulski on 24/01/2019.
//  Copyright © 2019 Michał Smulski. All rights reserved.
//

import Foundation

class CurrenciesRepository {
    private(set) var currenciesTable: CurrencyTable?
    private let service: CurrenciesService
    
    init(service: CurrenciesService) {
        self.service = service
    }
    
    func requestLatestTable(base: String, completion: @escaping ([Rate]) -> Void) {
        service.latestTable(base: base, completion: { [weak self] result in
            switch result {
            case .success(let table):
                self?.currenciesTable = table
                completion([Rate(currencySymbol: table.base, value: 1.0)] + table.rates)
            case .error(_):
                completion([])
            }
        })
    }
    
    func convert(_ amount: Double, of source: String, to target: String) -> Double {
        guard let currenciesTable = currenciesTable else {
            print("Missing currencies table for conversion. Please request one first!")
            return 0.0
        }
        return Converter(table: currenciesTable).convert(amount, of: source, to: target) ?? 0.0
    }
}
