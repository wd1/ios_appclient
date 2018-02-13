//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSYapDatabaseObject.h"

NS_ASSUME_NONNULL_BEGIN

@class TSThread;

typedef NS_ENUM(NSUInteger, TSPaymentState) {
    TSPaymentStateNone,
    TSPaymentStatePendingConfirmation,
    TSPaymentStateFailed,
    TSPaymentStateRejected,
    TSPaymentStateApproved
} NS_SWIFT_NAME(PaymentState) ;

typedef NS_ENUM(NSInteger, OWSInteractionType) {
    OWSInteractionType_Unknown,
    OWSInteractionType_IncomingMessage,
    OWSInteractionType_OutgoingMessage,
    OWSInteractionType_Error,
    OWSInteractionType_Call,
    OWSInteractionType_Info,
    OWSInteractionType_UnreadIndicator,
    OWSInteractionType_Offer,
};

@interface TSInteraction : TSYapDatabaseObject

- (instancetype)initWithTimestamp:(uint64_t)timestamp inThread:(TSThread *)thread;

@property (nonatomic, readonly) NSString *uniqueThreadId;
@property (nonatomic, readonly) TSThread *thread;
@property (nonatomic, readonly) uint64_t timestamp;

@property (nonatomic, assign) TSPaymentState paymentState;

- (NSString *)paymentStateText;

- (BOOL)isDynamicInteraction;

- (OWSInteractionType)interactionType;

- (TSThread *)threadWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;

- (BOOL)isDynamicInteraction;

- (OWSInteractionType)interactionType;

- (TSThread *)threadWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;

/**
 * When an interaction is updated, it often affects the UI for it's containing thread. Touching it's thread will notify
 * any observers so they can redraw any related UI.
 */
- (void)touchThreadWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;

#pragma mark Utility Method

+ (NSArray<TSInteraction *> *)interactionsWithTimestamp:(uint64_t)timestamp
                                                ofClass:(Class)clazz
                                        withTransaction:(YapDatabaseReadWriteTransaction *)transaction;

- (NSDate *)dateForSorting;
- (uint64_t)timestampForSorting;
- (NSComparisonResult)compareForSorting:(TSInteraction *)other;

// "Dynamic" interactions are not messages or static events (like
// info messages, error messages, etc.).  They are interactions
// created, updated and deleted by the views.
//
// These include block offers, "add to contact" offers,
// unseen message indicators, etc.
- (BOOL)isDynamicInteraction;

@end

NS_ASSUME_NONNULL_END

