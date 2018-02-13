//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "PhoneNumber.h"
#import "PhoneNumberUtil.h"
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>
#import <libPhoneNumber-iOS/NBMetadataHelper.h>
#import <libPhoneNumber-iOS/NBPhoneMetaData.h>
#import <libPhoneNumber-iOS/NBPhoneNumber.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>

static NSString *const RPDefaultsKeyPhoneNumberString    = @"RPDefaultsKeyPhoneNumberString";
static NSString *const RPDefaultsKeyPhoneNumberCanonical = @"RPDefaultsKeyPhoneNumberCanonical";

@interface PhoneNumber ()

@property (nonatomic, readonly) NBPhoneNumber *phoneNumber;
@property (nonatomic, readonly) NSString *e164;

@end

#pragma mark -

@implementation PhoneNumber

- (instancetype)initWithPhoneNumber:(NBPhoneNumber *)phoneNumber e164:(NSString *)e164
{
    if (self = [self init]) {
        OWSAssert(phoneNumber);
        OWSAssert(e164.length > 0);

        _phoneNumber = phoneNumber;
        _e164 = e164;
    }
    return self;
}

+ (PhoneNumber *)phoneNumberFromText:(NSString *)text andRegion:(NSString *)regionCode {
    OWSAssert(text != nil);
    OWSAssert(regionCode != nil);

    PhoneNumberUtil *phoneUtil = [PhoneNumberUtil sharedUtil];

    NSError *parseError   = nil;
    NBPhoneNumber *number = [phoneUtil parse:text defaultRegion:regionCode error:&parseError];

    if (parseError) {
        return nil;
    }

    NSError *toE164Error;
    NSString *e164 = [phoneUtil format:number numberFormat:NBEPhoneNumberFormatE164 error:&toE164Error];
    if (toE164Error) {
        DDLogDebug(@"Issue while formatting number: %@", [toE164Error description]);
        return nil;
    }

    return [[PhoneNumber alloc] initWithPhoneNumber:number e164:e164];
}

+ (PhoneNumber *)phoneNumberFromUserSpecifiedText:(NSString *)text {
    OWSAssert(text != nil);

    return [PhoneNumber phoneNumberFromText:text andRegion:[self defaultRegionCode]];
}

+ (NSString *)defaultRegionCode {
    NSString *defaultRegion;
#if TARGET_OS_IPHONE
    defaultRegion = [[PhoneNumberUtil sharedUtil].nbPhoneNumberUtil countryCodeByCarrier];

    if ([defaultRegion isEqualToString:@"ZZ"]) {
        defaultRegion = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    }
#else
    defaultRegion = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
#endif
    return defaultRegion;
}

+ (PhoneNumber *)phoneNumberFromE164:(NSString *)text {
    OWSAssert(text != nil);
    OWSAssert([text hasPrefix:COUNTRY_CODE_PREFIX]);
    PhoneNumber *number = [PhoneNumber phoneNumberFromText:text andRegion:@"ZZ"];

    OWSAssert(number != nil);
    return number;
}

+ (NSString *)bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:(NSString *)input {
    return [PhoneNumber bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:input
                                                               withSpecifiedRegionCode:[self defaultRegionCode]];
}

+ (NSString *)bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:(NSString *)input
                                              withSpecifiedCountryCodeString:(NSString *)countryCodeString {
    return [PhoneNumber
            bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:input
            withSpecifiedRegionCode:
            [PhoneNumber regionCodeFromCountryCodeString:countryCodeString]];
}

+ (NSString *)bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:(NSString *)input
                                                     withSpecifiedRegionCode:(NSString *)regionCode {
    NBAsYouTypeFormatter *formatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:regionCode];

    NSString *result = input;
    for (NSUInteger i = 0; i < input.length; i++) {
        result = [formatter inputDigit:[input substringWithRange:NSMakeRange(i, 1)]];
    }
    return result;
}


+ (NSString *)regionCodeFromCountryCodeString:(NSString *)countryCodeString {
    NBPhoneNumberUtil *phoneUtil = [PhoneNumberUtil sharedUtil].nbPhoneNumberUtil;
    NSString *regionCode =
    [phoneUtil getRegionCodeForCountryCode:@([[countryCodeString substringFromIndex:1] integerValue])];
    return regionCode;
}


+ (PhoneNumber *)tryParsePhoneNumberFromText:(NSString *)text fromRegion:(NSString *)regionCode {
    OWSAssert(text != nil);
    OWSAssert(regionCode != nil);

    return [self phoneNumberFromText:text andRegion:regionCode];
}

+ (PhoneNumber *)tryParsePhoneNumberFromUserSpecifiedText:(NSString *)text {
    OWSAssert(text != nil);

    if ([text isEqualToString:@""]) {
        return nil;
    }
    NSString *sanitizedString = [self removeFormattingCharacters:text];

    return [self phoneNumberFromUserSpecifiedText:sanitizedString];
}

+ (NSString *)nationalPrefixTransformRuleForDefaultRegion
{
    static NSString *result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *defaultRegionCode = [self defaultRegionCode];
        NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
        NBPhoneMetaData *defaultRegionMetadata = [helper getMetadataForRegion:defaultRegionCode];
        result = defaultRegionMetadata.nationalPrefixTransformRule;
    });
    return result;
}

// clientPhoneNumber is the local user's phone number and should never change.
+ (NSString *)nationalPrefixTransformRuleForClientPhoneNumber:(NSString *)clientPhoneNumber
{
    if (clientPhoneNumber.length < 1) {
        return nil;
    }
    static NSString *result = nil;
    static NSString *cachedClientPhoneNumber = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // clientPhoneNumber is the local user's phone number and should never change.
        NSNumber *localCallingCode = [[PhoneNumber phoneNumberFromE164:clientPhoneNumber] getCountryCode];
        if (localCallingCode != nil) {
            NSString *localCallingCodePrefix = [NSString stringWithFormat:@"+%@", localCallingCode];
            NSString *localCountryCode =
            [PhoneNumberUtil.sharedUtil probableCountryCodeForCallingCode:localCallingCodePrefix];
            if (localCountryCode && ![localCountryCode isEqualToString:[self defaultRegionCode]]) {
                NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
                NBPhoneMetaData *localNumberRegionMetadata = [helper getMetadataForRegion:localCountryCode];
                result = localNumberRegionMetadata.nationalPrefixTransformRule;
            }
        }
        cachedClientPhoneNumber = [clientPhoneNumber copy];
    });
    OWSAssert([cachedClientPhoneNumber isEqualToString:clientPhoneNumber]);
    return result;
}

+ (NSArray<PhoneNumber *> *)tryParsePhoneNumbersFromsUserSpecifiedText:(NSString *)text
                                                     clientPhoneNumber:(NSString *)clientPhoneNumber
{
    NSMutableArray<PhoneNumber *> *result =
    [[self tryParsePhoneNumbersFromNormalizedText:text clientPhoneNumber:clientPhoneNumber] mutableCopy];

    // A handful of countries (Mexico, Argentina, etc.) require a "national" prefix after
    // their country calling code.
    //
    // It's a bit hacky, but we reconstruct these national prefixes from libPhoneNumber's
    // parsing logic.  It's okay if we botch this a little.  The risk is that we end up with
    // some misformatted numbers with extra non-numeric regex syntax.  These erroneously
    // parsed numbers will never be presented to the user, since they'll never survive the
    // contacts intersection.
    //
    // 1. Try to apply a "national prefix" using the phone's region.
    //    NSString *nationalPrefixTransformRuleForDefaultRegion = [self nationalPrefixTransformRuleForDefaultRegion];
    //    if ([nationalPrefixTransformRuleForDefaultRegion containsString:@"$1"]) {
    //        NSString *normalizedText =
    //            [nationalPrefixTransformRuleForDefaultRegion stringByReplacingOccurrencesOfString:@"$1" withString:text];
    //        if (![normalizedText containsString:@"$"]) {
    //            [result addObjectsFromArray:[self tryParsePhoneNumbersFromNormalizedText:normalizedText
    //                                                                   clientPhoneNumber:clientPhoneNumber]];
    //        }
    //    }

    // 2. Try to apply a "national prefix" using the region that corresponds to the
    //    calling code for the local phone number.
    //    NSString *nationalPrefixTransformRuleForClientPhoneNumber =
    //        [self nationalPrefixTransformRuleForClientPhoneNumber:clientPhoneNumber];
    //    if ([nationalPrefixTransformRuleForClientPhoneNumber containsString:@"$1"]) {
    //        NSString *normalizedText =
    //            [nationalPrefixTransformRuleForClientPhoneNumber stringByReplacingOccurrencesOfString:@"$1"
    //                                                                                       withString:text];
    //        if (![normalizedText containsString:@"$"]) {
    //            [result addObjectsFromArray:[self tryParsePhoneNumbersFromNormalizedText:normalizedText
    //                                                                   clientPhoneNumber:clientPhoneNumber]];
    //        }
    //    }

    return [result copy];
}

+ (NSArray<PhoneNumber *> *)tryParsePhoneNumbersFromNormalizedText:(NSString *)text
                                                 clientPhoneNumber:(NSString *)clientPhoneNumber
{
    OWSAssert(text != nil);

    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([text isEqualToString:@""]) {
        return nil;
    }

    NSString *sanitizedString = [self removeFormattingCharacters:text];
    OWSAssert(sanitizedString != nil);

    NSMutableArray *result = [NSMutableArray new];
    NSMutableSet *phoneNumberSet = [NSMutableSet new];
    void (^tryParsingWithCountryCode)(NSString *, NSString *) = ^(NSString *text,
                                                                  NSString *countryCode) {
        PhoneNumber *phoneNumber = [PhoneNumber phoneNumberFromText:text
                                                          andRegion:countryCode];
        if (phoneNumber && [phoneNumber toE164] && ![phoneNumberSet containsObject:[phoneNumber toE164]]) {
            [result addObject:phoneNumber];
            [phoneNumberSet addObject:[phoneNumber toE164]];
        }
    };

    tryParsingWithCountryCode(sanitizedString, [self defaultRegionCode]);

    if ([sanitizedString hasPrefix:@"+"]) {
        // If the text starts with "+", don't try prepending
        // anything else.
        return result;
    }

    // Try just adding "+" and parsing it.
    tryParsingWithCountryCode([NSString stringWithFormat:@"+%@", sanitizedString], [self defaultRegionCode]);

    // Order matters; better results should appear first so prefer
    // matches with the same country code as this client's phone number.
    //    OWSAssert(clientPhoneNumber.length > 0);
    //    if (clientPhoneNumber.length > 0) {
    //        // Note that NBPhoneNumber uses "country code" to refer to what we call a
    //        // "calling code" (i.e. 44 in +44123123).  Within SSK we use "country code"
    //        // (and sometimes "region code") to refer to a country's ISO 2-letter code
    //        // (ISO 3166-1 alpha-2).
    //        NSNumber *callingCodeForLocalNumber = [[PhoneNumber phoneNumberFromE164:clientPhoneNumber] getCountryCode];
    //        if (callingCodeForLocalNumber != nil) {
    //            NSString *callingCodePrefix = [NSString stringWithFormat:@"+%@", callingCodeForLocalNumber];
    //
    //            tryParsingWithCountryCode(
    //                [callingCodePrefix stringByAppendingString:sanitizedString], [self defaultRegionCode]);
    //
    //            // Try to determine what the country code is for the local phone number
    //            // and also try parsing the phone number using that country code if it
    //            // differs from the device's region code.
    //            //
    //            // For example, a French person living in Italy might have an
    //            // Italian phone number but use French region/language for their
    //            // phone. They're likely to have both Italian and French contacts.
    //            NSString *localCountryCode =
    //                [PhoneNumberUtil.sharedUtil probableCountryCodeForCallingCode:callingCodePrefix];
    //            if (localCountryCode && ![localCountryCode isEqualToString:[self defaultRegionCode]]) {
    //                tryParsingWithCountryCode(
    //                    [callingCodePrefix stringByAppendingString:sanitizedString], localCountryCode);
    //            }
    //        }
    //    }

    return result;
}

+ (NSString *)removeFormattingCharacters:(NSString *)inputString {
    char outputString[inputString.length + 1];

    int outputLength = 0;
    for (NSUInteger i = 0; i < inputString.length; i++) {
        unichar c = [inputString characterAtIndex:i];
        if (c == '+' || (c >= '0' && c <= '9')) {
            outputString[outputLength++] = (char)c;
        }
    }

    outputString[outputLength] = 0;
    return [NSString stringWithUTF8String:(void *)outputString];
}

+ (PhoneNumber *)tryParsePhoneNumberFromE164:(NSString *)text {
    OWSAssert(text != nil);

    return [self phoneNumberFromE164:text];
}

- (NSURL *)toSystemDialerURL {
    NSString *link = [NSString stringWithFormat:@"telprompt://%@", self.e164];
    return [NSURL URLWithString:link];
}

- (NSString *)toE164 {
    return self.e164;
}

- (NSNumber *)getCountryCode {
    return self.phoneNumber.countryCode;
}

- (BOOL)isValid {
    return [[PhoneNumberUtil sharedUtil].nbPhoneNumberUtil isValidNumber:self.phoneNumber];
}

- (NSString *)localizedDescriptionForUser {
    NBPhoneNumberUtil *phoneUtil = [PhoneNumberUtil sharedUtil].nbPhoneNumberUtil;

    NSError *formatError = nil;
    NSString *pretty =
    [phoneUtil format:self.phoneNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:&formatError];

    if (formatError != nil) {
        return self.e164;
    }
    return pretty;
}

- (BOOL)resolvesInternationallyTo:(PhoneNumber *)otherPhoneNumber {
    return [self.toE164 isEqualToString:otherPhoneNumber.toE164];
}

- (NSString *)description {
    return self.e164;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.phoneNumber forKey:RPDefaultsKeyPhoneNumberString];
    [encoder encodeObject:self.e164 forKey:RPDefaultsKeyPhoneNumberCanonical];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super init])) {
        _phoneNumber = [decoder decodeObjectForKey:RPDefaultsKeyPhoneNumberString];
        _e164 = [decoder decodeObjectForKey:RPDefaultsKeyPhoneNumberCanonical];
    }
    return self;
}

- (NSComparisonResult)compare:(PhoneNumber *)other
{
    return [self.toE164 compare:other.toE164];
}

@end

