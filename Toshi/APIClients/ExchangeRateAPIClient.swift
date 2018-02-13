// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation
import Teapot
import AwesomeCache

let ExchangeRateClient = ExchangeRateAPIClient.shared

final class ExchangeRateAPIClient {

    static let shared: ExchangeRateAPIClient = ExchangeRateAPIClient()

    private static let collectionKey = "ethereumExchangeRate"
    private let currenciesCacheKey = "currenciesCacheKey"

    private let currenciesCachedData = CurrenciesCacheData()

    private lazy var cache: Cache<CurrenciesCacheData> = {
        do {
            return try Cache<CurrenciesCacheData>(name: "currenciesCache")
        } catch {
            fatalError("Couldn't instantiate the currencies cache")
        }
    }()

    var teapot: Teapot
    var baseURL: URL

    var exchangeRate: Decimal {
        if let rate = Yap.sharedInstance.retrieveObject(for: ExchangeRateAPIClient.collectionKey) as? Decimal {
            return rate
        } else {
            return 0
        }
    }

    convenience init(teapot: Teapot, cacheEnabled: Bool = true) {
        self.init()
        self.teapot = teapot

        if !cacheEnabled {
            self.cache.removeAllObjects()
        }
    }

    init() {
        baseURL = URL(string: ToshiExchangeRateServiceBaseURLPath)!
        teapot = Teapot(baseURL: baseURL)

        updateRate()

        Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.updateRate()
        }
    }

    func updateRate(_ completion: @escaping ((_ rate: Decimal?) -> Void) = { _ in }) {
        getRate { rate in
            if rate != nil {
                Yap.sharedInstance.insert(object: rate, for: ExchangeRateAPIClient.collectionKey)
            }

            DispatchQueue.main.async {
                completion(rate)
            }
        }
    }

    func getRate(_ completion: @escaping ((_ rate: Decimal?) -> Void)) {
        let code = TokenUser.current?.localCurrency ?? TokenUser.defaultCurrency

        teapot.get("/v1/rates/ETH/\(code)") { (result: NetworkResult) in
            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary, let usd = json["rate"] as? String, let doubleValue = Double(usd) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }

                DispatchQueue.main.async {
                    completion(Decimal(doubleValue))
                }
            case .failure(_, _, let error):
                DLog(error.localizedDescription)
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    func getCurrencies(_ completion: @escaping (([Currency]) -> Void)) {

        if let data = cache.object(forKey: currenciesCacheKey), let currencies = data.objects {
            completion(currencies)
        }

        teapot.get("/v1/currencies") { [weak self] (result: NetworkResult) in
            var results: [Currency] = []

            switch result {
            case .success(let json, _):
                guard let strongSelf = self, let json = json?.dictionary, let currencies = json["currencies"] as? [[String: String]] else {
                    DispatchQueue.main.async {
                        completion([])
                    }
                    
                    return
                }

                var validResults: [Currency] = []
                for currency in currencies {
                    guard let code = currency["code"], let name = currency["name"] else {
                        continue
                    }

                    validResults.append(Currency(code, name))
                }

                results = validResults
                strongSelf.currenciesCachedData.objects = validResults
                strongSelf.cache.setObject(strongSelf.currenciesCachedData, forKey: strongSelf.currenciesCacheKey)
            case .failure(_, _, let error):
                DLog(error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
}
