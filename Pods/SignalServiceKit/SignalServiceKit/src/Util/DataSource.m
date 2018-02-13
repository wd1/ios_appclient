//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "DataSource.h"
#import "MIMETypeUtil.h"
#import "NSData+Image.h"

NS_ASSUME_NONNULL_BEGIN

@interface DataSource ()

@property (nonatomic) BOOL shouldDeleteOnDeallocation;

// The file path for the data, if it already exists on disk.
//
// This method is safe to call as it will not do any expensive reads or writes.
//
// May return nil if the data does not (yet) reside on disk.
//
// Use dataUrl instead if you need to access the data; it will
// ensure the data is on disk and return a URL, barring an error.
- (nullable NSString *)dataPathIfOnDisk;

@end

#pragma mark -

@implementation DataSource

- (NSData *)data
{
    OWSFail(@"%@ Missing required method: data", self.tag);
    return nil;
}

- (nullable NSURL *)dataUrl
{
    OWSFail(@"%@ Missing required method: dataUrl", self.tag);
    return nil;
}

- (nullable NSString *)dataPathIfOnDisk
{
    OWSFail(@"%@ Missing required method: dataPathIfOnDisk", self.tag);
    return nil;
}

- (NSUInteger)dataLength
{
    OWSFail(@"%@ Missing required method: dataLength", self.tag);
    return 0;
}

- (BOOL)writeToPath:(NSString *)dstFilePath
{
    OWSFail(@"%@ Missing required method: writeToPath:", self.tag);
    return NO;
}

- (void)setShouldDeleteOnDeallocation
{
    self.shouldDeleteOnDeallocation = YES;
}

- (BOOL)isValidImage
{
    NSString *_Nullable dataPath = [self dataPathIfOnDisk];
    if (dataPath) {
        // if ows_isValidImage is given a file path, it will
        // avoid loading most of the data into memory, which
        // is considerably more performant, so try to do that.
        return [NSData ows_isValidImageAtPath:dataPath];
    }
    NSData *data = [self data];
    return [data ows_isValidImage];
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

#pragma mark -

@interface DataSourceValue ()

@property (nonatomic) NSData *dataValue;

@property (nonatomic) NSString *fileExtension;

// This property is lazy-populated.
@property (nonatomic) NSString *cachedFilePath;

@end

#pragma mark -

@implementation DataSourceValue

- (void)dealloc
{
    if (self.shouldDeleteOnDeallocation) {
        NSString *filePath = self.cachedFilePath;
        if (filePath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;
                BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
                if (!success || error) {
                    OWSCFail(@"DataSourceValue could not delete file: %@, %@", filePath, error);
                }
            });
        }
    }
}

+ (nullable DataSource *)dataSourceWithData:(NSData *)data fileExtension:(NSString *)fileExtension
{
    OWSAssert(data);

    if (!data) {
        return nil;
    }

    DataSourceValue *instance = [DataSourceValue new];
    instance.dataValue = data;
    instance.fileExtension = fileExtension;
    // Always try to clean up temp files created by this instance.
    [instance setShouldDeleteOnDeallocation];
    return instance;
}

+ (nullable DataSource *)dataSourceWithData:(NSData *)data utiType:(NSString *)utiType
{
    NSString *fileExtension = [MIMETypeUtil fileExtensionForUTIType:utiType];
    return [self dataSourceWithData:data fileExtension:fileExtension];
}

+ (nullable DataSource *)dataSourceWithOversizeText:(NSString *_Nullable)text
{
    if (!text) {
        return nil;
    }

    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    return [self dataSourceWithData:data fileExtension:kOversizeTextAttachmentFileExtension];
}

+ (DataSource *)dataSourceWithSyncMessage:(NSData *)data
{
    return [self dataSourceWithData:data fileExtension:kSyncMessageFileExtension];
}

+ (DataSource *)emptyDataSource
{
    return [self dataSourceWithData:[NSData new] fileExtension:@"bin"];
}

- (NSData *)data
{
    OWSAssert(self.dataValue);

    return self.dataValue;
}

- (nullable NSURL *)dataUrl
{
    NSString *_Nullable path = [self dataPath];
    return (path ? [NSURL fileURLWithPath:path] : nil);
}

- (nullable NSString *)dataPath
{
    OWSAssert(self.dataValue);

    @synchronized(self)
    {
        if (!self.cachedFilePath) {
            NSString *dirPath = NSTemporaryDirectory();
            NSString *fileName = [[[NSUUID UUID] UUIDString] stringByAppendingPathExtension:self.fileExtension];
            NSString *filePath = [dirPath stringByAppendingPathComponent:fileName];
            if ([self writeToPath:filePath]) {
                self.cachedFilePath = filePath;
            } else {
                OWSFail(@"%@ Could not write data to disk: %@", self.tag, self.fileExtension);
            }
        }

        return self.cachedFilePath;
    }
}

- (nullable NSString *)dataPathIfOnDisk
{
    return self.cachedFilePath;
}

- (NSUInteger)dataLength
{
    OWSAssert(self.dataValue);

    return self.dataValue.length;
}

- (BOOL)writeToPath:(NSString *)dstFilePath
{
    OWSAssert(self.dataValue);

    // There's an odd bug wherein instances of NSData/Data created in Swift
    // code reliably crash on iOS 9 when calling [NSData writeToFile:...].
    // We can avoid these crashes by simply copying the Data.
    NSData *dataCopy = (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(10, 0) ? self.dataValue : [self.dataValue copy]);

    BOOL success = [dataCopy writeToFile:dstFilePath atomically:YES];
    if (!success) {
        OWSFail(@"%@ Could not write data to disk: %@", self.tag, dstFilePath);
        return NO;
    } else {
        return YES;
    }
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

#pragma mark -

@interface DataSourcePath ()

@property (nonatomic) NSString *filePath;

// These properties are lazy-populated.
@property (nonatomic) NSData *cachedData;
@property (nonatomic) NSNumber *cachedDataLength;

@end

#pragma mark -

@implementation DataSourcePath

- (void)dealloc
{
    if (self.shouldDeleteOnDeallocation) {
        NSString *filePath = self.filePath;
        if (filePath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;
                BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
                if (!success || error) {
                    OWSCFail(@"DataSourcePath could not delete file: %@, %@", filePath, error);
                }
            });
        }
    }
}

+ (nullable DataSource *)dataSourceWithURL:(NSURL *)fileUrl;
{
    OWSAssert(fileUrl);

    if (!fileUrl || ![fileUrl isFileURL]) {
        return nil;
    }
    DataSourcePath *instance = [DataSourcePath new];
    instance.filePath = fileUrl.path;
    return instance;
}

+ (nullable DataSource *)dataSourceWithFilePath:(NSString *)filePath;
{
    OWSAssert(filePath);

    if (!filePath) {
        return nil;
    }

    DataSourcePath *instance = [DataSourcePath new];
    instance.filePath = filePath;
    OWSAssert(!instance.shouldDeleteOnDeallocation);
    return instance;
}

- (void)setFilePath:(NSString *)filePath
{
    OWSAssert(filePath.length > 0);

#ifdef DEBUG
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    OWSAssert(exists);
    OWSAssert(!isDirectory);
#endif

    _filePath = filePath;
}

- (NSData *)data
{
    OWSAssert(self.filePath);

    @synchronized(self)
    {
        if (!self.cachedData) {
            DDLogError(@"%@ ---- reading data", self.tag);
            self.cachedData = [NSData dataWithContentsOfFile:self.filePath];
        }
        if (!self.cachedData) {
            OWSFail(@"%@ Could not read data from disk: %@", self.tag, self.filePath);
            self.cachedData = [NSData new];
        }
        return self.cachedData;
    }
}

- (nullable NSURL *)dataUrl
{
    OWSAssert(self.filePath);

    return [NSURL fileURLWithPath:self.filePath];
}

- (nullable NSString *)dataPath
{
    OWSAssert(self.filePath);

    return self.filePath;
}

- (nullable NSString *)dataPathIfOnDisk
{
    OWSAssert(self.filePath);

    return self.filePath;
}

- (NSUInteger)dataLength
{
    OWSAssert(self.filePath);

    @synchronized(self)
    {
        if (!self.cachedDataLength) {
            NSError *error;
            NSDictionary<NSFileAttributeKey, id> *_Nullable attributes =
                [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:&error];
            if (!attributes || error) {
                OWSFail(@"%@ Could not read data length from disk: %@, %@", self.tag, self.filePath, error);
                self.cachedDataLength = @(0);
            } else {
                uint64_t fileSize = [attributes fileSize];
                self.cachedDataLength = @(fileSize);
            }
        }
        return [self.cachedDataLength unsignedIntegerValue];
    }
}

- (BOOL)writeToPath:(NSString *)dstFilePath
{
    OWSAssert(self.filePath);

    NSError *error;
    BOOL success = [[NSFileManager defaultManager] copyItemAtPath:self.filePath toPath:dstFilePath error:&error];
    if (!success || error) {
        OWSFail(@"%@ Could not write data from path: %@, to path: %@, %@", self.tag, self.filePath, dstFilePath, error);
        return NO;
    } else {
        return YES;
    }
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
