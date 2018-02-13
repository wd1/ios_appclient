#import "UserBootstrapParameters.h"
#import <AxolotlKit/PreKeyBundle.h>

@interface UserBootstrapParameters()
@property (nonnull, nonatomic) NSString *expectedAddres;
@property (nonnull, nonatomic) NSString *identityKey;

@property (nonnull, nonatomic) NSArray *prekeysArray;

@property (nonnull, nonatomic) NSString *password;

@property (nonatomic) UInt32 registrationId;

@property (nonnull, nonatomic) NSString *signalingKey;

@property (nonnull, nonatomic) NSData *signedPreKey;
@property (nonnull, nonatomic) NSData *lastResortPreKey;

@property (nonatomic) NSTimeInterval *timestamp;

@property (nullable, nonatomic) NSString *signature;

@property (nonnull, nonatomic, readonly) NSDictionary <NSString *, id> *payload;

@end

@implementation UserBootstrapParameters

- (NSDictionary<NSString *,id> *)payload {
    for (prekey) {

    }
}

        var prekeys = [[String: Any]]()
        for prekey in self.prekeys {
            let prekeyParam: [String: Any] = [
                                              "keyId": prekey.preKeyId(),
                                              "publicKey": prekey.keyPair().publicKey.base64EncodedStringWithoutPadding()
                                              ]
            prekeys.append(prekeyParam)
        }

        let payload: [String: Any] = [
                                      "identityKey" : self.identityKey,
                                      "lastResortKey": [
                                                        "keyId": Int(self.lastResortPreKey.preKeyId()),
                                                        "publicKey": self.lastResortPreKey.keyPair().publicKey.base64EncodedStringWithoutPadding()
                                                        ],
                                      "password": self.password,
                                      "preKeys": prekeys,
                                      "registrationId": Int(self.registrationId),
                                      "signalingKey": self.signalingKey,
                                      "signedPreKey": [
                                                       "keyId": Int(self.signedPrekey.preKeyId()),
                                                       "publicKey": self.signedPrekey.keyPair().publicKey.base64EncodedStringWithoutPadding(),
                                                       "signature": self.signedPrekey.signature().base64EncodedStringWithoutPadding()
                                                       ],
                                      "timestamp": self.timestamp
                                      ]

        return payload
    }()

    init(store: SignalStorageManager, ethereumAddress: String) {
        self.expectedAddress = ethereumAddress
        self.identityKey = store.getIdentityKeyPair().publicKey.base64EncodedStringWithoutPadding()
        self.lastResortPreKey = store.lastResortPreKey
        self.password = DeviceSpecificPassword
        self.prekeys = store.keyHelper.generatePreKeys(withStartingPreKeyId: 0, count: 100)

        self.registrationId = store.getLocalRegistrationId()

        self.signalingKey = store.signalingKey
        self.signedPrekey = store.keyHelper.generateSignedPreKey(withIdentity: store.getIdentityKeyPair(), signedPreKeyId: 0)

        self.timestamp = Int(floor(Date().timeIntervalSince1970))

        for prekey in self.prekeys {
            store.storePreKey(prekey.serializedData(), preKeyId: prekey.preKeyId())
        }
        store.storeSignedPreKey(signedPrekey.serializedData(), signedPreKeyId: signedPrekey.preKeyId())
    }
    
    func stringForSigning() -> String {
        let payload = self.payload
        let serializedString = OrderedSerializer.string(from: payload)
        
        return serializedString
    }
    
    func signedParametersDictionary() -> [String: Any]? {
        guard let signature = self.signature else { return nil }
        
        let params: [String: Any] = [
                                     "payload": self.payload,
                                     "signature": signature,
                                     "address": self.expectedAddress
                                     ]
        
        return params
    }
}
@end
