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

// Each key is a value that came from the init request as stated above.
// Example: SofaInitialResponse(content: ["paymentAddress": "0xa2a0134f1df987bc388dbcb635dfeed4ce497e2a", "language": "en"])
final class SofaInitialResponse: SofaWrapper {
    override var type: SofaType {
        return .initialResponse
    }

    convenience init(initialRequest: SofaInitialRequest) {
        var response = [String: Any]()
        for value in initialRequest.values {
            if value == "paymentAddress" {
                response[value] = TokenUser.current?.paymentAddress ?? ""
            } else if value == "language" {
                let locale = Locale.current
                response[value] = locale.identifier
            }
        }

        self.init(content: response)
    }
}
