//
//  Currency.swift
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

final class CurrenciesCacheData: NSObject, NSCoding {

    var objects: [Currency]?

    override init() {
        super.init()
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(objects, forKey: "objects")
    }

    init?(coder aDecoder: NSCoder) {
        if let currencies = aDecoder.decodeObject(forKey: "objects") as? [Currency] {
            objects = currencies
        }

        super.init()
    }
}

final class Currency: NSObject, NSCoding {

    var code: String = ""
    var name: String = ""

    func encode(with aCoder: NSCoder) {
        aCoder.encode(code, forKey: "code")
        aCoder.encode(name, forKey: "name")
    }

    init?(coder aDecoder: NSCoder) {
        if let code = aDecoder.decodeObject(forKey: "code") as? String {
            self.code = code
        }

        if let name = aDecoder.decodeObject(forKey: "name") as? String {
            self.name = name
        }

        super.init()
    }

    init(_ code: String, _ name: String) {
        self.code = code
        self.name = name
    }

    static let forcedLocale = Locale(identifier: "en_US")

    static let defaultLocalesForCurrencies = [
                                                "AED": "ar_AE",
                                                "ALL": "en_AL",
                                                "AMD": "hy_AM",
                                                "ANG": "en_SX",
                                                "ARS": "es_AR",
                                                "AUD": "en_AU",
                                                "AWG": "nl_AW",
                                                "BAM": "en_BA",
                                                "BBD": "en_BB",
                                                "BDT": "bn_BD",
                                                "BGN": "bg_BG",
                                                "BHD": "ar_BH",
                                                "BIF": "en_BI",
                                                "BMD": "en_BM",
                                                "BRL": "en_BR",
                                                "BSD": "en_BS",
                                                "BTN": "dz_BT",
                                                "BWP": "en_BW",
                                                "BZD": "en_BZ",
                                                "CAD": "en_CA",
                                                "CHF": "en_CH",
                                                "CLP": "es_CL",
                                                "CNY": "en_CN",
                                                "COP": "es_CO",
                                                "CRC": "es_CR",
                                                "CUP": "es_CU",
                                                "CZK": "en_CZ",
                                                "DKK": "en_DK",
                                                "DOP": "es_DO",
                                                "EGP": "ar_EG",
                                                "ERN": "en_ER",
                                                "EUR": "en_DE",
                                                "FJD": "en_FJ",
                                                "FKP": "en_FK",
                                                "GBP": "en_GB",
                                                "GHS": "en_GH",
                                                "GIP": "en_GI",
                                                "GMD": "en_GM",
                                                "GTQ": "es_GT",
                                                "GYD": "en_GY",
                                                "HKD": "en_HK",
                                                "HNL": "es_HN",
                                                "HRK": "en_HR",
                                                "HTG": "fr_HT",
                                                "HUF": "en_HU",
                                                "IDR": "id_ID",
                                                "ILS": "en_IL",
                                                "INR": "en_IN",
                                                "ISK": "en_IS",
                                                "JMD": "en_JM",
                                                "JOD": "ar_JO",
                                                "JPY": "jp_JP",
                                                "KES": "en_KE",
                                                "KHR": "km_KH",
                                                "KPW": "ko_KP",
                                                "KRW": "en_KR",
                                                "KWD": "ar_KW",
                                                "KYD": "en_KY",
                                                "LAK": "lo_LA",
                                                "LBP": "ar_LB",
                                                "LRD": "en_LR",
                                                "LYD": "ar_LY",
                                                "MGA": "en_MG",
                                                "MMK": "my_MM",
                                                "MNT": "mn_MN",
                                                "MOP": "en_MO",
                                                "MUR": "en_MU",
                                                "MVR": "en_MV",
                                                "MWK": "en_MW",
                                                "MXN": "es_MX",
                                                "MYR": "en_MY",
                                                "NAD": "en_NA",
                                                "NGN": "en_NG",
                                                "NIO": "es_NI",
                                                "NOK": "en_NO",
                                                "NPR": "ne_NP",
                                                "NZD": "en_NZ",
                                                "OMR": "ar_OM",
                                                "PAB": "es_PA",
                                                "PGK": "en_PG",
                                                "PHP": "en_PH",
                                                "PKR": "en_PK",
                                                "PLN": "en_PL",
                                                "PYG": "es_PY",
                                                "QAR": "ar_QA",
                                                "RON": "en_RO",
                                                "RUB": "en_RU",
                                                "RWF": "en_RW",
                                                "SAR": "ar_SA",
                                                "SBD": "en_SB",
                                                "SCR": "en_SC",
                                                "SDG": "en_SD",
                                                "SEK": "en_SE",
                                                "SGD": "en_SG",
                                                "SHP": "en_SH",
                                                "SLL": "en_SL",
                                                "SRD": "nl_SR",
                                                "SSP": "en_SS",
                                                "STD": "pt_ST",
                                                "SZL": "en_SZ",
                                                "THB": "th_TH",
                                                "TJS": "tg_TJ",
                                                "TMT": "tk_TM",
                                                "TOP": "en_TO",
                                                "TRY": "en_TR",
                                                "TTD": "en_TT",
                                                "TWD": "en_TW",
                                                "TZS": "en_TZ",
                                                "UGX": "en_UG",
                                                "USD": "en_US",
                                                "UYU": "es_UY",
                                                "VEF": "es_VE",
                                                "VND": "vi_VN",
                                                "VUV": "en_VU",
                                                "WST": "en_WS",
                                                "XAF": "en_CM",
                                                "YER": "ar_YE",
                                                "ZMW": "en_ZM"
    ]
}
