#import "EmptyCallHandler.h"

@implementation EmptyCallHandler

- (void)receivedBusy:(OWSSignalServiceProtosCallMessageBusy *)busy fromCallerId:(NSString *)callerId {

}

- (void)receivedOffer:(OWSSignalServiceProtosCallMessageOffer *)offer fromCallerId:(NSString *)callerId {

}

- (void)receivedAnswer:(OWSSignalServiceProtosCallMessageAnswer *)answer fromCallerId:(NSString *)callerId {

}

- (void)receivedHangup:(OWSSignalServiceProtosCallMessageHangup *)hangup fromCallerId:(NSString *)callerId {

}

- (void)receivedIceUpdate:(OWSSignalServiceProtosCallMessageIceUpdate *)iceUpdate fromCallerId:(NSString *)callerId {
    
}

@end
