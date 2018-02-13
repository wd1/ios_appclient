//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSReadReceiptsForSenderMessage.h"
#import "NSDate+OWS.h"
#import "OWSSignalServiceProtos.pb.h"
#import "SignalRecipient.h"

NS_ASSUME_NONNULL_BEGIN

@interface OWSReadReceiptsForSenderMessage ()

@property (nonatomic, readonly) NSArray<NSNumber *> *messageTimestamps;

@end

@implementation OWSReadReceiptsForSenderMessage

- (instancetype)initWithThread:(nullable TSThread *)thread messageTimestamps:(NSArray<NSNumber *> *)messageTimestamps;
{
    self = [super initWithTimestamp:[NSDate ows_millisecondTimeStamp] inThread:thread];
    if (!self) {
        return self;
    }

    _messageTimestamps = [messageTimestamps copy];

    return self;
}

#pragma mark - TSOutgoingMessage overrides

- (BOOL)shouldSyncTranscript
{
    return NO;
}

- (BOOL)isSilent
{
    // Avoid "phantom messages" for "recipient read receipts".

    return YES;
}

- (NSData *)buildPlainTextData:(SignalRecipient *)recipient
{
    OWSAssert(recipient);

    OWSSignalServiceProtosContentBuilder *contentBuilder = [OWSSignalServiceProtosContentBuilder new];
    [contentBuilder setReceiptMessage:[self buildReceiptMessage:recipient.recipientId]];
    return [[contentBuilder build] data];
}

- (OWSSignalServiceProtosReceiptMessage *)buildReceiptMessage:(NSString *)recipientId
{
    OWSSignalServiceProtosReceiptMessageBuilder *builder = [OWSSignalServiceProtosReceiptMessageBuilder new];

    [builder setType:OWSSignalServiceProtosReceiptMessageTypeRead];
    OWSAssert(self.messageTimestamps.count > 0);
    for (NSNumber *messageTimestamp in self.messageTimestamps) {
        [builder addTimestamp:[messageTimestamp unsignedLongLongValue]];
    }

    return [builder build];
}

#pragma mark - TSYapDatabaseObject overrides

- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    // override superclass with no-op.
    //
    // There's no need to save this message, since it's not displayed to the user.
    //
    // Should we find a need to save this in the future, we need to exclude any non-serializable properties.
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@ with message timestamps: %zd", self.tag, self.messageTimestamps.count];
}

#pragma mark - Logging

+ (NSString *)tag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)tag
{
    return self.class.tag;
}

@end

NS_ASSUME_NONNULL_END
