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

final class AvatarManager: NSObject {

    @objc static let shared = AvatarManager()

    private lazy var imageCache: Cache<UIImage> = {
        do {
            return try Cache<UIImage>(name: "imageCache")
        } catch {
            fatalError("Couldn't instantiate the image cache")
        }
    }()

    private var teapots = [String: Teapot]()

    private lazy var downloadOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 10
        queue.name = "Download avatars queue"

        return queue
    }()

    func refreshAvatar(at path: String) {
        imageCache.removeObject(forKey: path)
    }

    @objc func cleanCache() {
        imageCache.removeAllObjects()
    }

    @objc func startDownloadContactsAvatars() {
        downloadOperationQueue.cancelAllOperations()

        let operation = BlockOperation()
        operation.addExecutionBlock { [weak self] in

            let avatarPaths: [String] = SessionManager.shared.contactsManager.tokenContacts.flatMap { contact in
                contact.avatarPath
            }

            if let currentUserAvatarPath = TokenUser.current?.avatarPath {
                self?.downloadAvatar(for: currentUserAvatarPath)
            }

            for path in avatarPaths {
                if operation.isCancelled { return }
                self?.downloadAvatar(for: path)
            }
        }

        downloadOperationQueue.addOperation(operation)
    }

    private func baseURL(from url: URL) -> String? {
        if url.baseURL == nil {
            guard let scheme = url.scheme, let host = url.host else { return nil }
            return "\(scheme)://\(host)"
        }

        return url.baseURL?.absoluteString
    }

    private func teapot(for url: URL) -> Teapot? {
        guard let base = baseURL(from: url) else { return nil }
        if teapots[base] == nil {
            guard let baseUrl = URL(string: base) else { return nil }
            teapots[base] = Teapot(baseURL: baseUrl)
        }

        return teapots[base]
    }

    func downloadAvatar(for key: String, completion: ((UIImage?, String?) -> Void)? = nil) {
        if key.hasAddressPrefix {
            if let avatar = cachedAvatar(for: key) {
                completion?(avatar, key)
                return
            }

            IDAPIClient.shared.findContact(name: key) { [weak self] user in

                guard let retrievedUser = user else {
                    completion?(nil, key)
                    return
                }

                UserDefaults.standard.set(retrievedUser.avatarPath, forKey: key)
                self?.downloadAvatar(path: retrievedUser.avatarPath, completion: completion)
            }
        }

        guard imageCache.object(forKey: key) == nil else { return }

        downloadAvatar(path: key)
    }

    private func downloadAvatar(path: String, completion: ((UIImage?, String?) -> Void)? = nil) {
        DispatchQueue.global().async {
            
            if let cachedAvatar = self.cachedAvatar(for: path) {
                DispatchQueue.main.async {
                    completion?(cachedAvatar, path)
                }

                return
            }

            guard let url = URL(string: path), let teapot = self.teapot(for: url) else {
                DispatchQueue.main.async {
                    completion?(nil, path)
                }
                
                return
            }

            teapot.get(url.relativePath) { [weak self] (result: NetworkImageResult) in
                guard let strongSelf = self else {
                    DispatchQueue.main.async {
                        completion?(nil, path)
                    }

                    return
                }

                var resultImage: UIImage?
                switch result {
                case .success(let image, _):
                    strongSelf.imageCache.setObject(image, forKey: path)
                    resultImage = image
                case .failure(let response, let error):
                    DLog("\(response)")
                    DLog("\(error)")
                }

                DispatchQueue.main.async {
                    completion?(resultImage, path)
                }
            }
        }
    }

    /// Downloads or finds avatar for given key.
    ///
    /// - Parameters:
    ///   - key: token_id/address or resource url path.
    ///   - completion: The completion closure to fire when the request completes or image is found in cache.
    ///                 - image: Found in cache or fetched image.
    ///                 - path: Path for found in cache or fetched image.
    func avatar(for key: String, completion: @escaping ((UIImage?, String?) -> Void)) {
        if key.hasAddressPrefix {
            if let avatarPath = UserDefaults.standard.object(forKey: key) as? String {
                _avatar(for: avatarPath, completion: completion)
            } else {
                downloadAvatar(for: key, completion: completion)
            }
        }

        _avatar(for: key, completion: completion)
    }

    /// Downloads or finds avatar for the resource url path.
    ///
    /// - Parameters:
    ///   - path: An resource url path.
    ///   - completion: The completion closure to fire when the request completes or image is found in cache.
    ///                 - image: Found in cache or fetched image.
    ///                 - path: Path for found in cache or fetched image.
    private func _avatar(for path: String, completion: @escaping ((UIImage?, String?) -> Void)) {
        guard let avatar = imageCache.object(forKey: path) else {
            downloadAvatar(path: path, completion: completion)
            return
        }

        completion(avatar, path)
    }

    /// Finds avatar for the given key.
    ///
    /// - Parameters:
    ///   - key: token_id/address or resource url path.
    /// - Returns:
    ///   - found image or nil if not present
    @objc func cachedAvatar(for key: String) -> UIImage? {
        if key.hasAddressPrefix {
            guard let avatarPath = UserDefaults.standard.object(forKey: key) as? String else { return nil }

            return cachedAvatar(for: avatarPath)
        }

        return imageCache.object(forKey: key)
    }
}
