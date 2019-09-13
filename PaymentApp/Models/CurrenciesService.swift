//
//  CurrenciesService.swift
//  RevolutTest
//
//  Created by Michał Smulski on 23/01/2019.
//  Copyright © 2019 Michał Smulski. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case error(Error)
}

class CurrenciesService {
    enum Error: Swift.Error {
        case missingData
    }
    
    private let baseUrl: URL
    private let session: URLSession
    
    init(baseUrl: URL, session: URLSession = URLSession(configuration: .ephemeral)) {
        self.baseUrl = baseUrl
        self.session = session
    }
    
    func latestTable(base: String, completion: @escaping (Result<CurrencyTable>) -> Void) {
        session.dataTask(with: request(base: base)) { data, _, error in
            switch (data, error) {
            case (_, let error?):
                completion(.error(error))
            case (nil, _):
                completion(.error(CurrenciesService.Error.missingData))
            case (let data?, _) where data.isEmpty:
                completion(.error(CurrenciesService.Error.missingData))
            case (let data?, _):
                do {
                    let decoder = JSONDecoder()
                    let table = try decoder.decode(CurrencyTable.self, from: data)
                    completion(.success(table))
                } catch(let error) {
                    completion(.error(error))
                }
            }
        }.resume()
    }
}

private extension CurrenciesService {
    func fullUrl(base: String) -> URL {
        let fullUrl = baseUrl.appendingPathComponent("latest")
        guard var comps = URLComponents(url: fullUrl, resolvingAgainstBaseURL: false) else { return fullUrl }
        
        var updatedItems = comps.queryItems ?? []
        updatedItems.append(URLQueryItem(name: "base", value: base))
        comps.queryItems = updatedItems
        
        return comps.url ?? fullUrl
    }
    
    func request(base: String) -> URLRequest {
        return URLRequest(url: fullUrl(base: base))
    }
}
