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

extension UIImage {

    var stringInQRCode: String? {
        let options: [String: Any] = [
            CIDetectorAccuracy: CIDetectorAccuracyHigh,
            CIDetectorAspectRatio: 1.0
        ]
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: options) else {
            assertionFailure("Can't create qrCodeDetector")
            return nil
        }

        guard let imageData = UIImagePNGRepresentation(self) else {
            assertionFailure("Could not convert image into PNG data")
            return nil
        }

        guard let ciImage = CIImage(data: imageData) else {
            assertionFailure("Can't get ci image from imageData")
            return nil
        }

        guard
            let features = detector.features(in: ciImage) as? [CIQRCodeFeature],
            let feature = features.first else {
                // No QR code detected
                return nil
        }

        return feature.messageString
    }
}
