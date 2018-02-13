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

struct ToshiError: Error, CustomStringConvertible {
    static func dataTaskError(withUnderLyingError error: Error) -> TeapotError {
        let errorDescription = String(format: NSLocalizedString("toshi_error_data_task_error", bundle: Teapot.localizationBundle, comment: ""), error.localizedDescription)

        return TeapotError(withType: .dataTaskError, description: errorDescription, underlyingError: error)
    }

    static let invalidPayload = ToshiError(withType: .invalidPayload, description: Localized("toshi_error_invalid_payload"))
    static let invalidResponseJSON = ToshiError(withType: .invalidResponseJSON, description: Localized("toshi_error_invalid_response_json"))

    static func invalidResponseStatus(_ status: Int) -> ToshiError {
        let errorDescription = String(format: NSLocalizedString("teapot_invalid_response_status", bundle: Teapot.localizationBundle, comment: ""), status)

        return ToshiError(withType: .invalidResponseStatus, description: errorDescription, responseStatus: status)
    }

    static let genericError = ToshiError(withType: .generic, description: Localized("toshi_generic_error"))

    enum ErrorType: Int {
        case dataTaskError
        case invalidPayload
        case invalidRequestPath
        case invalidResponseStatus
        case invalidResponseJSON
        case generic
    }

    let type: ErrorType
    let description: String
    let responseStatus: Int?
    let underlyingError: Error?

    init(withType errorType: ErrorType, description: String, responseStatus: Int? = nil, underlyingError: Error? = nil) {
        self.type = errorType
        self.description = description
        self.responseStatus = responseStatus
        self.underlyingError = underlyingError
    }
}

extension ToshiError {
    static func teapotErrorTypeToToshiErrorType(_ teapotErrorType: TeapotError.ErrorType) -> ErrorType {
        switch teapotErrorType {
        case .invalidResponseStatus:
            return .invalidResponseStatus
        case .dataTaskError:
            return .dataTaskError
        case .invalidPayload:
            return .invalidPayload
        case .invalidRequestPath:
            return .invalidRequestPath
        default:
            return .generic
        }
    }

    init(withTeapotError teapotError: TeapotError, errorDescription: String? = nil) {
        let errorType = ToshiError.teapotErrorTypeToToshiErrorType(teapotError.type)

        let validErrorDescription = errorDescription ?? teapotError.description
        self.init(withType: errorType, description: validErrorDescription, responseStatus: teapotError.responseStatus, underlyingError: teapotError.underlyingError)
    }
}
