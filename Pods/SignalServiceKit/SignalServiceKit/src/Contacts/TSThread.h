//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSYapDatabaseObject.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TSInteraction;
@class TSInvalidIdentityKeyReceivingErrorMessage;

/**
 *  TSThread is the superclass of TSContactThread and TSGroupThread
 */

@interface TSThread : TSYapDatabaseObject

@property (nonatomic, assign) BOOL isPendingAccept;

// YES IFF this thread has ever had a message.
@property (nonatomic) BOOL hasEverHadMessage;

/**
 *  Whether the object is a group thread or not.
 *
 *  @return YES if is a group thread, NO otherwise.
 */
- (BOOL)isGroupThread;

/**
 *  Returns the name of the thread.
 *
 *  @return The name of the thread.
 */
- (NSString *)name;

/**
 * @returns
 *   Signal Id (e164) of the contact if it's a contact thread.
 */
- (nullable NSString *)contactIdentifier;

/**
 * @returns recipientId for each recipient in the thread
 */
@property (nonatomic, readonly) NSArray<NSString *> *recipientIdentifiers;

#if TARGET_OS_IOS

/**
 *  Returns the image representing the thread. Nil if not available.
 *
 *  @return UIImage of the thread, or nil.
 */
- (nullable UIImage *)image;
#endif

#pragma mark Interactions

/**
 *  @return The number of interactions in this thread.
 */
- (NSUInteger)numberOfInteractions;

/**
 * Get all messages in the thread we weren't able to decrypt
 */
- (NSArray<TSInvalidIdentityKeyReceivingErrorMessage *> *)receivedMessagesForInvalidKey:(NSData *)key;

/**
 *  Returns whether or not the thread has unread messages.
 *
 *  @return YES if it has unread TSIncomingMessages, NO otherwise.
 */
- (BOOL)hasUnreadMessages;

- (BOOL)hasSafetyNumbers;

- (void)markAllAsReadWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;

/**
 *  Returns the latest date of a message in the thread or the thread creation date if there are no messages in that
 *thread.
 *
 *  @return The date of the last message or thread creation date.
 */
- (NSDate *)lastMessageDate;

/**
 *  Returns the string that will be displayed typically in a conversations view as a preview of the last message
 *received in this thread.
 *
 *  @return Thread preview string.
 */
- (NSString *)lastMessageLabel;

/**
 *  Updates the thread's caches of the latest interaction.
 *
 *  @param lastMessage Latest Interaction to take into consideration.
 *  @param transaction Database transaction.
 */
- (void)updateWithLastMessage:(TSInteraction *)lastMessage transaction:(YapDatabaseReadWriteTransaction *)transaction;

#pragma mark Archival

/**
 *  Returns the last date at which a string was archived or nil if the thread was never archived or brought back to the
 *inbox.
 *
 *  @return Last archival date.
 */
- (nullable NSDate *)archivalDate;

/**
 *  Archives a thread with the current date.
 *
 *  @param transaction Database transaction.
 */
- (void)archiveThreadWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;

/**
 *  Archives a thread with the reference date. This is currently only used for migrating older data that has already
 * been archived.
 *
 *  @param transaction Database transaction.
 *  @param date        Date at which the thread was archived.
 */
- (void)archiveThreadWithTransaction:(YapDatabaseReadWriteTransaction *)transaction referenceDate:(NSDate *)date;

/**
 *  Unarchives a thread that was archived previously.
 *
 *  @param transaction Database transaction.
 */
- (void)unarchiveThreadWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;

#pragma mark Drafts

/**
 *  Returns the last known draft for that thread. Always returns a string. Empty string if nil.
 *
 *  @param transaction Database transaction.
 *
 *  @return Last known draft for that thread.
 */
- (NSString *)currentDraftWithTransaction:(YapDatabaseReadTransaction *)transaction;

/**
 *  Sets the draft of a thread. Typically called when leaving a conversation view.
 *
 *  @param draftString Draft string to be saved.
 *  @param transaction Database transaction.
 */
- (void)setDraft:(NSString *)draftString transaction:(YapDatabaseReadWriteTransaction *)transaction;

@property (atomic, readonly) BOOL isMuted;
@property (atomic, readonly, nullable) NSDate *mutedUntilDate;

// This model may be updated from many threads. We don't want to save
// our local copy (this instance) since it may be out of date.  Instead, we
// use these "updateWith..." methods to:
//
// a) Update a property of this instance.
// b) Load an up-to-date instance of this model from from the data store.
// c) Update and save that fresh instance.
// d) If this instance hasn't yet been saved, save this local instance.
//
// After "updateWith...":
//
// a) An updated copy of this instance will always have been saved in the
//    data store.
// b) The local property on this instance will always have been updated.
// c) Other properties on this instance may be out of date.
//
// All mutable properties of this class have been made read-only to
// prevent accidentally modifying them directly.
//
// This isn't a perfect arrangement, but in practice this will prevent
// data loss and will resolve all known issues.
- (void)updateWithMutedUntilDate:(NSDate *)mutedUntilDate;

@end

NS_ASSUME_NONNULL_END
