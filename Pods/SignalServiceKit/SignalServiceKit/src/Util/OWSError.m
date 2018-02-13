//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSError.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const OWSSignalServiceKitErrorDomain = @"OWSSignalServiceKitErrorDomain";

NSError *OWSErrorWithCodeDescription(OWSErrorCode code, NSString *description)
{
    return [NSError errorWithDomain:OWSSignalServiceKitErrorDomain
                               code:code
                           userInfo:@{ NSLocalizedDescriptionKey: description }];
}

NSError *OWSErrorMakeUnableToProcessServerResponseError()
{
    return OWSErrorWithCodeDescription(OWSErrorCodeUnableToProcessServerResponse,
        NSLocalizedString(@"ERROR_DESCRIPTION_SERVER_FAILURE", @"Generic server error"));
}

NSError *OWSErrorMakeFailedToSendOutgoingMessageError()
{
    return OWSErrorWithCodeDescription(OWSErrorCodeFailedToSendOutgoingMessage,
        NSLocalizedString(@"ERROR_DESCRIPTION_CLIENT_SENDING_FAILURE", @"Generic notice when message failed to send."));
}

NSError *OWSErrorMakeNoSuchSignalRecipientError()
{
    return OWSErrorWithCodeDescription(OWSErrorCodeNoSuchSignalRecipient,
        NSLocalizedString(
            @"ERROR_DESCRIPTION_UNREGISTERED_RECIPIENT", @"Error message when attempting to send message"));
}

NSError *OWSErrorMakeAssertionError()
{
    return OWSErrorWithCodeDescription(OWSErrorCodeFailedToSendOutgoingMessage,
                                       NSLocalizedString(@"ERROR_DESCRIPTION_UNKNOWN_ERROR", @"Worst case generic error message"));
}

NSError *OWSErrorMakeMessageSendDisabledDueToPreKeyUpdateFailuresError()
{
    return OWSErrorWithCodeDescription(OWSErrorCodeMessageSendDisabledDueToPreKeyUpdateFailures,
        NSLocalizedString(@"ERROR_DESCRIPTION_MESSAGE_SEND_DISABLED_PREKEY_UPDATE_FAILURES",
            @"Error mesage indicating that message send is disabled due to prekey update failures"));
}

NSError *OWSErrorMakeMessageSendFailedToBlockListError()
{
    return OWSErrorWithCodeDescription(OWSErrorCodeMessageSendFailedToBlockList,
        NSLocalizedString(@"ERROR_DESCRIPTION_MESSAGE_SEND_FAILED_DUE_TO_BLOCK_LIST",
            @"Error mesage indicating that message send failed due to block list"));
}

NSError *OWSErrorMakeWriteAttachmentDataError()
{
    return OWSErrorWithCodeDescription(OWSErrorCodeCouldNotWriteAttachmentData,
        NSLocalizedString(@"ERROR_DESCRIPTION_MESSAGE_SEND_FAILED_DUE_TO_FAILED_ATTACHMENT_WRITE",
            @"Error mesage indicating that message send failed due to failed attachment write"));
}

NS_ASSUME_NONNULL_END
