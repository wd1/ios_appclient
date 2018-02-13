//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "NSString+OWS.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSString (OWS)

- (NSString *)ows_stripped
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end

NS_ASSUME_NONNULL_END
