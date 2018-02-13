//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSConstants.h"
#import <Mantle/Mantle.h>

/**
 * Contstructs the per-device-message parameters used when submitting a message to
 * the Signal Web Service.
 *
 * See:
 * https://github.com/WhisperSystems/libsignal-service-java/blob/master/java/src/main/java/org/whispersystems/signalservice/internal/push/OutgoingPushMessage.java
 */
@interface OWSMessageServiceParams : MTLModel <MTLJSONSerializing>

@property (nonatomic, readonly) int type;
@property (nonatomic, readonly) NSString *destination;
@property (nonatomic, readonly) int destinationDeviceId;
@property (nonatomic, readonly) int destinationRegistrationId;
@property (nonatomic, readonly) NSString *content;
@property (nonatomic, readonly) BOOL silent;

- (instancetype)initWithType:(TSWhisperMessageType)type
                 recipientId:(NSString *)destination
                      device:(int)deviceId
                     content:(NSData *)content
                    isSilent:(BOOL)isSilent
              registrationId:(int)registrationId;

@end
