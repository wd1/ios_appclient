//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSVerificationStateSyncMessage.h"
#import "Cryptography.h"
#import "OWSIdentityManager.h"
#import "OWSSignalServiceProtos.pb.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -

@interface OWSVerificationStateSyncMessage ()

@property (nonatomic, readonly) OWSVerificationState verificationState;
@property (nonatomic, readonly) NSData *identityKey;

@end

#pragma mark -

@implementation OWSVerificationStateSyncMessage

- (instancetype)initWithVerificationState:(OWSVerificationState)verificationState
                              identityKey:(NSData *)identityKey
               verificationForRecipientId:(NSString *)verificationForRecipientId
{
    OWSAssert(identityKey.length == kIdentityKeyLength);
    OWSAssert(verificationForRecipientId.length > 0);

    // we only sync user's marking as un/verified. Never sync the conflicted state, the sibling device
    // will figure that out on it's own.
    OWSAssert(verificationState != OWSVerificationStateNoLongerVerified);

    self = [super init];
    if (!self) {
        return self;
    }

    _verificationState = verificationState;
    _identityKey = identityKey;
    _verificationForRecipientId = verificationForRecipientId;
    
    // This sync message should be 1-512 bytes longer than the corresponding NullMessage
    // we store this values so the corresponding NullMessage can subtract it from the total length.
    _paddingBytesLength = arc4random_uniform(512) + 1;

    return self;
}

- (OWSSignalServiceProtosSyncMessageBuilder *)syncMessageBuilder
{
    OWSAssert(self.identityKey.length == kIdentityKeyLength);
    OWSAssert(self.verificationForRecipientId.length > 0);

    // we only sync user's marking as un/verified. Never sync the conflicted state, the sibling device
    // will figure that out on it's own.
    OWSAssert(self.verificationState != OWSVerificationStateNoLongerVerified);

    OWSSignalServiceProtosSyncMessageBuilder *syncMessageBuilder = [OWSSignalServiceProtosSyncMessageBuilder new];

    OWSSignalServiceProtosVerifiedBuilder *verifiedBuilder = [OWSSignalServiceProtosVerifiedBuilder new];
    verifiedBuilder.destination = self.verificationForRecipientId;
    verifiedBuilder.identityKey = self.identityKey;
    verifiedBuilder.state = OWSVerificationStateToProtoState(self.verificationState);

    OWSAssert(self.paddingBytesLength != 0);

    // We add the same amount of padding in the VerificationStateSync message and it's coresponding NullMessage so that
    // the sync message is indistinguishable from an outgoing Sent transcript corresponding to the NullMessage. We pad
    // the NullMessage so as to obscure it's content. The sync message (like all sync messages) will be *additionally*
    // padded by the superclass while being sent. The end result is we send a NullMessage of a non-distinct size, and a
    // verification sync which is ~1-512 bytes larger then that.
    verifiedBuilder.nullMessage = [Cryptography generateRandomBytes:self.paddingBytesLength];
    
    syncMessageBuilder.verifiedBuilder = verifiedBuilder;
    
    return syncMessageBuilder;
}

- (size_t)unpaddedVerifiedLength
{
    OWSAssert(self.identityKey.length == kIdentityKeyLength);
    OWSAssert(self.verificationForRecipientId.length > 0);

    // we only sync user's marking as un/verified. Never sync the conflicted state, the sibling device
    // will figure that out on it's own.
    OWSAssert(self.verificationState != OWSVerificationStateNoLongerVerified);

    OWSSignalServiceProtosVerifiedBuilder *verifiedBuilder = [OWSSignalServiceProtosVerifiedBuilder new];
    verifiedBuilder.destination = self.verificationForRecipientId;
    verifiedBuilder.identityKey = self.identityKey;
    verifiedBuilder.state = OWSVerificationStateToProtoState(self.verificationState);

    return [verifiedBuilder build].data.length;
}

@end

NS_ASSUME_NONNULL_END
