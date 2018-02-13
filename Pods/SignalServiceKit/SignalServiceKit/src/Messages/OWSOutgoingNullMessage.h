//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSOutgoingMessage.h"

NS_ASSUME_NONNULL_BEGIN

@class OWSVerificationStateSyncMessage;
@class TSContactThread;

@interface OWSOutgoingNullMessage : TSOutgoingMessage

- (instancetype)initWithContactThread:(TSContactThread *)contactThread
         verificationStateSyncMessage:(OWSVerificationStateSyncMessage *)verificationStateSyncMessage;

@end

NS_ASSUME_NONNULL_END
