#import "TSThread+Additions.h"
#import <objc/runtime.h>
#import "Toshi-Swift.h"

@implementation TSThread (Additions)

- (NSArray<TSMessage *> *)messages {
    NSMutableArray *visible = [NSMutableArray array];

    for (TSInteraction *interaction in self.allInteractions) {
        if ([interaction isKindOfClass:[TSMessage class]]) {
            NSString *body = ((TSMessage *)interaction).body;
            // We use hard-coded strings here since the constants for them are declared inside a swift enum
            // hence inaccessible through Objective C. Since we only use it here, I left them as literals.g
            if ([body hasPrefix:[SofaTypes message]] || [body hasPrefix:[SofaTypes paymentRequest]]) {
                [visible addObject:interaction];
            }
        }
    }

    return visible;
}

@end
