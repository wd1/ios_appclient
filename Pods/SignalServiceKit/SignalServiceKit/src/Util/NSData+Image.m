//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "NSData+Image.h"

typedef NS_ENUM(NSInteger, ImageFormat) {
    ImageFormat_Unknown,
    ImageFormat_Png,
    ImageFormat_Gif,
    ImageFormat_Tiff,
    ImageFormat_Jpeg,
    ImageFormat_Bmp,
};

@implementation NSData (Image)

+ (BOOL)ows_isValidImageAtPath:(NSString *)filePath
{
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    if (error) {
        DDLogError(@"%@ could not read image data: %@", self.tag, error);
    }

    return [data ows_isValidImage];
}

- (BOOL)ows_isValidImage
{
    // Don't trust the file extension; iOS (e.g. UIKit, Core Graphics) will happily
    // load a .gif with a .png file extension.
    //
    // Instead, use the "magic numbers" in the file data to determine the image format.
    ImageFormat imageFormat = [self ows_guessImageFormat];
    if (imageFormat == ImageFormat_Gif) {
        return [self ows_hasValidGifSize];
    } else if (imageFormat == ImageFormat_Unknown) {
        return NO;
    } else {
        return YES;
    }
}

- (ImageFormat)ows_guessImageFormat
{
    const NSUInteger kTwoBytesLength = 2;
    if (self.length < kTwoBytesLength) {
        return ImageFormat_Unknown;
    }

    unsigned char bytes[kTwoBytesLength];
    [self getBytes:&bytes range:NSMakeRange(0, kTwoBytesLength)];

    unsigned char byte0 = bytes[0];
    unsigned char byte1 = bytes[1];

    if (byte0 == 0x47 && byte1 == 0x49) {
        return ImageFormat_Gif;
    } else if (byte0 == 0x89 && byte1 == 0x50) {
        return ImageFormat_Png;
    } else if (byte0 == 0xff && byte1 == 0xd8) {
        return ImageFormat_Jpeg;
    } else if (byte0 == 0x42 && byte1 == 0x4d) {
        return ImageFormat_Bmp;
    } else if (byte0 == 0x4D && byte1 == 0x4D) {
        // Motorola byte order TIFF
        return ImageFormat_Tiff;
    } else if (byte0 == 0x49 && byte1 == 0x49) {
        // Intel byte order TIFF
        return ImageFormat_Tiff;
    }

    return ImageFormat_Unknown;
}

+ (BOOL)ows_areByteArraysEqual:(NSUInteger)length left:(unsigned char *)left right:(unsigned char *)right
{
    for (NSUInteger i = 0; i < length; i++) {
        if (left[i] != right[i]) {
            return NO;
        }
    }
    return YES;
}

// Parse the GIF header to prevent the "GIF of death" issue.
//
// See: https://blog.flanker017.me/cve-2017-2416-gif-remote-exec/
// See: https://www.w3.org/Graphics/GIF/spec-gif89a.txt
- (BOOL)ows_hasValidGifSize
{
    const NSUInteger kSignatureLength = 3;
    const NSUInteger kVersionLength = 3;
    const NSUInteger kWidthLength = 2;
    const NSUInteger kHeightLength = 2;
    const NSUInteger kPrefixLength = kSignatureLength + kVersionLength;
    const NSUInteger kBufferLength = kSignatureLength + kVersionLength + kWidthLength + kHeightLength;

    if (self.length < kBufferLength) {
        return NO;
    }

    unsigned char bytes[kBufferLength];
    [self getBytes:&bytes range:NSMakeRange(0, kBufferLength)];

    unsigned char kGif87APrefix[kPrefixLength] = {
        0x47, 0x49, 0x46, 0x38, 0x37, 0x61,
    };
    unsigned char kGif89APrefix[kPrefixLength] = {
        0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
    };
    if (![NSData ows_areByteArraysEqual:kPrefixLength left:bytes right:kGif87APrefix]
        && ![NSData ows_areByteArraysEqual:kPrefixLength left:bytes right:kGif89APrefix]) {
        return NO;
    }
    NSUInteger width = ((NSUInteger)bytes[kPrefixLength + 0]) | (((NSUInteger)bytes[kPrefixLength + 1] << 8));
    NSUInteger height = ((NSUInteger)bytes[kPrefixLength + 2]) | (((NSUInteger)bytes[kPrefixLength + 3] << 8));

    // We need to ensure that the image size is "reasonable".
    // We impose an arbitrary "very large" limit on image size
    // to eliminate harmful values.
    const NSUInteger kMaxValidSize = 1 << 18;

    return (width > 0 && width < kMaxValidSize && height > 0 && height < kMaxValidSize);
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
