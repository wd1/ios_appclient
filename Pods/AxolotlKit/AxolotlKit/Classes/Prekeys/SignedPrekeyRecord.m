//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "SignedPrekeyRecord.h"

static NSString* const kCoderPreKeyId        = @"kCoderPreKeyId";
static NSString* const kCoderPreKeyPair      = @"kCoderPreKeyPair";
static NSString* const kCoderPreKeyDate      = @"kCoderPreKeyDate";
static NSString* const kCoderPreKeySignature = @"kCoderPreKeySignature";
static NSString *const kCoderPreKeyWasAcceptedByService = @"kCoderPreKeyWasAcceptedByService";

@implementation SignedPreKeyRecord

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (instancetype)initWithId:(int)identifier
                   keyPair:(ECKeyPair *)keyPair
                 signature:(NSData *)signature
               generatedAt:(NSDate *)generatedAt
      wasAcceptedByService:(BOOL)wasAcceptedByService
{
    self = [super initWithId:identifier keyPair:keyPair];

    if (self) {
        _signature = signature;
        _generatedAt = generatedAt;
        _wasAcceptedByService = wasAcceptedByService;
    }

    return self;
}

- (instancetype)initWithId:(int)identifier keyPair:(ECKeyPair *)keyPair signature:(NSData*)signature generatedAt:(NSDate *)generatedAt{
    self = [super initWithId:identifier keyPair:keyPair];
    
    if (self) {
        _signature = signature;
        _generatedAt = generatedAt;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithId:[aDecoder decodeIntForKey:kCoderPreKeyId]
                     keyPair:[aDecoder decodeObjectOfClass:[ECKeyPair class] forKey:kCoderPreKeyPair]
                   signature:[aDecoder decodeObjectOfClass:[NSData class] forKey:kCoderPreKeySignature]
                 generatedAt:[aDecoder decodeObjectOfClass:[NSDate class] forKey:kCoderPreKeyDate]
        wasAcceptedByService:[aDecoder decodeBoolForKey:kCoderPreKeyWasAcceptedByService]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeInt:self.Id forKey:kCoderPreKeyId];
    [aCoder encodeObject:self.keyPair forKey:kCoderPreKeyPair];
    [aCoder encodeObject:self.signature forKey:kCoderPreKeySignature];
    [aCoder encodeObject:self.generatedAt forKey:kCoderPreKeyDate];
    [aCoder encodeBool:self.wasAcceptedByService forKey:kCoderPreKeyWasAcceptedByService];
}

- (instancetype)initWithId:(int)identifier keyPair:(ECKeyPair*)keyPair{
    NSAssert(FALSE, @"Signed PreKeys need a signature");
    return nil;
}

- (void)markAsAcceptedByService
{
    _wasAcceptedByService = YES;
}

@end
