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

import UIKit

/// Centralized generation of QR code images
struct QRCodeGenerator {

    enum QRCodeType {
        case
        /// - username: The Toshi username which you wish to display for scanning.
        addUser(username: String),
        /// - address: The ethereum address you wish to display for scanning.
        ethereumAddress(address: String)

        fileprivate var scannableAddress: String {
            switch self {
            case .addUser(let username):
                return "https://app.toshi.org/add/\(username)"
            case .ethereumAddress(let address):
                return "ethereum:\(address)"
            }
        }
    }

    /// Main QR Code generation method
    ///
    /// - Parameters:
    ///   - type: The type of QR code (with its associated value) to use for the
    ///   - resizeRate: CIFilter result is 31x31 pixels in size - set this rate to positive for enlarging and negative for shrinking. Defaults to 20.
    ///
    /// - Returns: A UIImage with the given QR code
    static func qrCodeImage(for type: QRCodeType, resizeRate: CGFloat = 20) -> UIImage {
        return UIImage.imageQRCode(for: type.scannableAddress, resizeRate: resizeRate)
    }
}
