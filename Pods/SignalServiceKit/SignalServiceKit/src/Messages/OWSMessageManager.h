//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSMessageHandler.h"

NS_ASSUME_NONNULL_BEGIN

@class OWSSignalServiceProtosEnvelope;
@class TSThread;
@class YapDatabaseReadWriteTransaction;

@interface OWSMessageManager : OWSMessageHandler

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)sharedManager;

// processEnvelope: can be called from any thread.
- (void)processEnvelope:(OWSSignalServiceProtosEnvelope *)envelope
          plaintextData:(NSData *_Nullable)plaintextData
            transaction:(YapDatabaseReadWriteTransaction *)transaction;

- (NSUInteger)unreadMessagesCount;
- (NSUInteger)unreadMessagesCountExcept:(TSThread *)thread;
- (NSUInteger)unreadMessagesInThread:(TSThread *)thread;

@end

NS_ASSUME_NONNULL_END
