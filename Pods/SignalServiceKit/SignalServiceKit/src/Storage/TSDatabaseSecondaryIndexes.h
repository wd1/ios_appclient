//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import <YapDatabase/YapDatabaseSecondaryIndex.h>
#import <YapDatabase/YapDatabaseTransaction.h>

@interface TSDatabaseSecondaryIndexes : NSObject

+ (YapDatabaseSecondaryIndex *)registerTimeStampIndex;

+ (void)enumerateMessagesWithTimestamp:(uint64_t)timestamp
                             withBlock:(void (^)(NSString *collection, NSString *key, BOOL *stop))block
                      usingTransaction:(YapDatabaseReadWriteTransaction *)transaction;

@end
