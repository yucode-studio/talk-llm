//
// Copyright (c) Microsoft. All rights reserved.
// See https://aka.ms/csspeech/license201809 for the full license information.
//

#include "SPXFoundation.h"

/**
 * Represents audio processing constants used for specifying the processing in AudioProcessingOptions.
 */
typedef NS_OPTIONS(NSUInteger, SPXAudioProcessingConstants)
{
    /**
    * Disables built-in input audio processing.
    */
    SPX_AUDIO_INPUT_PROCESSING_NONE = 0x00000000,
    /**
    * Enable voice activity detection in input audio processing.
    */
    SPX_AUDIO_INPUT_PROCESSING_ENABLE_VOICE_ACTIVITY_DETECTION = 0x00000020
};

/**
 * Represents audio processing options used with audio config class.
 */
SPX_EXPORT
@interface SPXAudioProcessingOptions : NSObject

/**
 * Initializes an SPXAudioProcessingOptions object using audio processing flags.
 *
 * @param audioProcessingFlags the flags to control the audio processing performed by Speech SDK. It is bitwise OR of SPX_AUDIO_INPUT_PROCESSING_XXX constants from SPXAudioProcessingConstants enum.
 * @return an instance of audio processing options.
 */
- (nonnull instancetype)init:(SPXAudioProcessingConstants)audioProcessingFlags;

/**
 * The type of audio processing performed by Speech SDK.
 * Bitwise OR of SPX_AUDIO_INPUT_PROCESSING_XXX constant flags from SPXAudioProcessingConstants enum indicating the input audio processing performed by Speech SDK.
 */
@property (readonly)SPXAudioProcessingConstants audioProcessingFlags;

@end
