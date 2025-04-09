//
// Copyright (c) Microsoft. All rights reserved.
// See https://aka.ms/csspeech/license for the full license information.
//
#import "SPXFoundation.h"
#import "SPXSpeechTranslationConfiguration.h"
#import "SPXAudioConfiguration.h"
#import "SPXRecognizer.h"
#import "SPXTranslationRecognitionResult.h"
#import "SPXTranslationRecognitionEventArgs.h"
#import "SPXTranslationSynthesisResult.h"
#import "SPXTranslationSynthesisEventArgs.h"
#import "SPXEmbeddedSpeechConfiguration.h"
#import "SPXAutoDetectSourceLanguageConfiguration.h"

/**
 * Performs translation on the specified speech input, and gets transcribed and translated texts as result.
 */
SPX_EXPORT
@interface SPXTranslationRecognizer : SPXRecognizer

typedef void (^SPXTranslationRecognitionEventHandler)(SPXTranslationRecognizer * _Nonnull, SPXTranslationRecognitionEventArgs * _Nonnull);
typedef void (^SPXTranslationRecognitionCanceledEventHandler)(SPXTranslationRecognizer * _Nonnull, SPXTranslationRecognitionCanceledEventArgs * _Nonnull);
typedef void (^SPXTranslationRecognitionAsyncCompletionHandler)(void);
typedef void (^SPXTranslationSynthesisEventHandler)(SPXTranslationRecognizer * _Nonnull, SPXTranslationSynthesisEventArgs * _Nonnull);

/**
 * Authorization token used to communicate with the translation recognition service.
 *
 * Note: The caller needs to ensure that the authorization token is valid. Before the authorization token expires,
 * the caller needs to refresh it by calling this setter with a new valid token.
 * Otherwise, the recognizer will encounter errors during recognition.
 */
@property (nonatomic, copy, nullable)NSString *authorizationToken;

/**
 * All target languages that have been configured for translation.
 * 
 * Added in version 1.7.0.
 */
@property (nonatomic, copy, readonly, nonnull)NSArray *targetLanguages;

/**
 * Initializes a new instance of translation recognizer.
 *
 * @param translationConfiguration translation recognition configuration.
 * @return an instance of translation recognizer.
 */
- (nullable instancetype)init:(nonnull SPXSpeechTranslationConfiguration *)translationConfiguration
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Initializes a new instance of translation recognizer.
 *
 * Added in version 1.6.0.
 *
 * @param translationConfiguration translation recognition configuration.
 * @param outError error information.
 * @return an instance of translation recognizer.
 */
- (nullable instancetype)init:(nonnull SPXSpeechTranslationConfiguration *)translationConfiguration error:(NSError * _Nullable * _Nullable)outError;

/**
 * Initializes a new instance of translation recognizer using the specified speech and audio configurations.
 *
 * @param translationConfiguration speech translation recognition configuration.
 * @param audioConfiguration audio configuration.
 * @return an instance of translation recognizer.
 */
- (nullable instancetype)initWithSpeechTranslationConfiguration:(nonnull SPXSpeechTranslationConfiguration *)translationConfiguration audioConfiguration:(nonnull SPXAudioConfiguration *)audioConfiguration
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Initializes a new instance of translation recognizer using the specified speech and audio configurations.
 *
 * Added in version 1.6.0.
 *
 * @param translationConfiguration speech translation recognition configuration.
 * @param audioConfiguration audio configuration.
 * @param outError error information.
 * @return an instance of translation recognizer.
 */
- (nullable instancetype)initWithSpeechTranslationConfiguration:(nonnull SPXSpeechTranslationConfiguration *)translationConfiguration audioConfiguration:(nonnull SPXAudioConfiguration *)audioConfiguration error:(NSError * _Nullable * _Nullable)outError;

/**
 * Initializes a new instance of translation recognizer using the specified auto language detection configuration.
 *
 * @param translationConfiguration speech translation configuration.
 * @param autoDetectSourceLanguageConfiguration auto language detection configuration.
 * @return an instance of translation recognizer.
 */
- (nullable instancetype)initWithSpeechTranslationConfiguration:(nonnull SPXSpeechTranslationConfiguration *)translationConfiguration
                          autoDetectSourceLanguageConfiguration:(nonnull SPXAutoDetectSourceLanguageConfiguration *)autoDetectSourceLanguageConfiguration
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Initializes a new instance of translation recognizer using the specified auto language detection configuration.
 *
 * @param translationConfiguration speech translation configuration.
 * @param autoDetectSourceLanguageConfiguration auto language detection configuration.
 * @param outError error information.
 * @return an instance of translation recognizer.
 */
- (nullable instancetype)initWithSpeechTranslationConfiguration:(nonnull SPXSpeechTranslationConfiguration *)translationConfiguration
                          autoDetectSourceLanguageConfiguration:(nonnull SPXAutoDetectSourceLanguageConfiguration *)autoDetectSourceLanguageConfiguration
                                                          error:(NSError * _Nullable * _Nullable)outError;

/**
 * Initializes a new instance of translation recognizer using specified auto language detection and audio configuration.
 *
 * @param translationConfiguration speech translation configuration.
 * @param autoDetectSourceLanguageConfiguration auto language detection configuration.
 * @param audioConfiguration audio configuration.
 * @return an instance of translation recognizer.
 */
- (nullable instancetype)initWithSpeechTranslationConfiguration:(nonnull SPXSpeechTranslationConfiguration *)translationConfiguration
                          autoDetectSourceLanguageConfiguration:(nonnull SPXAutoDetectSourceLanguageConfiguration *)autoDetectSourceLanguageConfiguration
                                             audioConfiguration:(nonnull SPXAudioConfiguration *)audioConfiguration
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Initializes a new instance of translation recognizer using specified auto language detection and audio configuration.
 *
 * @param translationConfiguration speech translation configuration.
 * @param autoDetectSourceLanguageConfiguration auto language detection configuration.
 * @param audioConfiguration audio configuration.
 * @param outError error information.
 * @return an instance of translation recognizer.
 */
- (nullable instancetype)initWithSpeechTranslationConfiguration:(nonnull SPXSpeechTranslationConfiguration *)translationConfiguration
                          autoDetectSourceLanguageConfiguration:(nonnull SPXAutoDetectSourceLanguageConfiguration *)autoDetectSourceLanguageConfiguration
                                             audioConfiguration:(nonnull SPXAudioConfiguration *)audioConfiguration
                                                          error:(NSError * _Nullable * _Nullable)outError;

/**
 * Initializes a new instance of translation recognizer.
 *
 * @param embeddedSpeechConfiguration embedded speech configuration.
 * @return an instance of translation recognizer.
 */
- (nullable instancetype)initWithEmbeddedSpeechConfiguration:(nonnull SPXEmbeddedSpeechConfiguration *)embeddedSpeechConfiguration
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Initializes a new instance of translation recognizer.
 *
 * @param embeddedSpeechConfiguration embedded speech configuration.
 * @param outError error information.
 * @return an instance of translation recognizer.
 */
- (nullable instancetype)initWithEmbeddedSpeechConfiguration:(nonnull SPXEmbeddedSpeechConfiguration *)embeddedSpeechConfiguration error:(NSError * _Nullable * _Nullable)outError;

/**
 * Initializes a new instance of translation recognizer using the specified speech and audio configurations.
 *
 * @param embeddedSpeechConfiguration embedded speech configuration.
 * @param audioConfiguration audio configuration.
 * @return an instance of translation recognizer.
 */
- (nullable instancetype)initWithEmbeddedSpeechConfiguration:(nonnull SPXEmbeddedSpeechConfiguration *)embeddedSpeechConfiguration audioConfiguration:(nonnull SPXAudioConfiguration *)audioConfiguration
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Initializes a new instance of translation recognizer using the specified speech and audio configurations.
 *
 * @param embeddedSpeechConfiguration embedded speech configuration.
 * @param audioConfiguration audio configuration.
 * @param outError error information.
 * @return an instance of translation recognizer.
 */
- (nullable instancetype)initWithEmbeddedSpeechConfiguration:(nonnull SPXEmbeddedSpeechConfiguration *)embeddedSpeechConfiguration audioConfiguration:(nonnull SPXAudioConfiguration *)audioConfiguration error:(NSError * _Nullable * _Nullable)outError;

/**
 * Starts speech translation, and returns after a single utterance is recognized. The end of a
 * single utterance is determined by listening for silence at the end or until a maximum of about 30
 * seconds of audio is processed.  The task returns the recognition text as result. 
 *
 * Note: Since recognizeOnce() returns only a single utterance, it is suitable only for single
 * shot recognition like command or query. 
 * For long-running multi-utterance recognition, use startContinuousRecognition() instead.
 *
 * @return the result of translation.
 */
- (nonnull SPXTranslationRecognitionResult *)recognizeOnce
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.") NS_RETURNS_RETAINED;

/**
 * Starts speech translation, and returns after a single utterance is recognized. The end of a
 * single utterance is determined by listening for silence at the end or until a maximum of about 30
 * seconds of audio is processed.  The task returns the recognition text as result. 
 *
 * Note: Since recognizeOnce() returns only a single utterance, it is suitable only for single
 * shot recognition like command or query. 
 * For long-running multi-utterance recognition, use startContinuousRecognition() instead.
 *
 * Added in version 1.6.0.
 *
 * @param outError error information.
 * @return the result of translation.
 */
- (nullable SPXTranslationRecognitionResult *)recognizeOnce:(NSError * _Nullable * _Nullable)outError NS_RETURNS_RETAINED;

/**
 * Starts translation, and returns after a single utterance is recognized. The end of a
 * single utterance is determined by listening for silence at the end or until a maximum of about 30
 * seconds of audio is processed.  The task returns the recognition text as result. 
 *
 * Note: Since recognizeOnceAsync() returns only a single utterance, it is suitable only for single
 * shot recognition like command or query. 
 * For long-running multi-utterance recognition, use startContinuousRecognition() instead.
 *
 * @param resultReceivedHandler the block function to be called when the first utterance has been recognized.
    */
- (void)recognizeOnceAsync:(nonnull void (^)(SPXTranslationRecognitionResult * _Nonnull))resultReceivedHandler
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Starts translation, and returns after a single utterance is recognized. The end of a
 * single utterance is determined by listening for silence at the end or until a maximum of about 30
 * seconds of audio is processed.  The task returns the recognition text as result. 
 *
 * Note: Since recognizeOnceAsync() returns only a single utterance, it is suitable only for single
 * shot recognition like command or query. 
 * For long-running multi-utterance recognition, use startContinuousRecognition() instead.
 *
 * Added in version 1.6.0.
 *
 * @param resultReceivedHandler the block function to be called when the first utterance has been recognized.
 * @param outError error information.
 */
- (BOOL)recognizeOnceAsync:(nonnull void (^)(SPXTranslationRecognitionResult * _Nonnull))resultReceivedHandler error:(NSError * _Nullable * _Nullable)outError;

/**
 * Starts speech translation on a continuous audio stream, until stopContinuousRecognition() is called.
 * The user must subscribe to events to receive translation results.
 */
- (void)startContinuousRecognition
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Starts speech translation on a continuous audio stream, until stopContinuousRecognition() is called.
 * The user must subscribe to events to receive translation results.
 *
 * Added in version 1.6.0.
 *
 * @param outError error information.
 */
- (BOOL)startContinuousRecognition:(NSError * _Nullable * _Nullable)outError;

/**
 * Stops continuous translation.
 */
- (void)stopContinuousRecognition
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Stops continuous translation.
 *
 * Added in version 1.6.0.
 *
 * @param outError error information.
 */
- (BOOL)stopContinuousRecognition:(NSError * _Nullable * _Nullable)outError;

/**
 * Begins a speech-to-text interaction with this recognizer using a keyword.
 * This interaction will use the provided keyword model to listen for a keyword indefinitely,
 * during which audio is not sent to the speech service and all processing is performed locally.
 * When a keyword is recognized, TranslationRecognizer will automatically connect to the speech service
 * and begin sending audio data from just before the keyword.
 * When received, speech-to-text results may be processed by the provided result handler
 * or retrieved via a subscription to the recognized event.
 *
 * @param keywordModel the keyword recognition model.
 * @param outError error information.
 * @return a value indicating whether the requested keyword recognition successfully started. If NO, outError may
 * contain additional information.
 */
- (BOOL)startKeywordRecognition
             :(nonnull SPXKeywordRecognitionModel *)keywordModel
        error:(NSError * _Nullable * _Nullable)outError;

/**
 * Begins a speech-to-text interaction with this recognizer using a keyword.
 * This interaction will use the provided keyword model to listen for a keyword indefinitely,
 * during which audio is not sent to the speech service and all processing is performed locally.
 * When a keyword is recognized, TranslationRecognizer will automatically connect to the speech service
 * and begin sending audio data from just before the keyword.
 * When received, speech-to-text results may be processed by the provided result handler
 * or retrieved via a subscription to the recognized event.
 *
 * @param keywordModel the keyword recognition model.
 */
- (void)startKeywordRecognition:(nonnull SPXKeywordRecognitionModel *)keywordModel
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Asynchronously begins a speech-to-text interaction with this recognizer
 * and immediately returns execution to the calling thread.
 * This interaction will use the provided keyword model to listen for a keyword indefinitely,
 * during which audio is not sent to the speech service and all processing is performed locally.
 * When a keyword is recognized, TranslationRecognizer will automatically connect to the speech service
 * and begin sending audio data from just before the keyword.
 * When received, speech-to-text results may be processed by the provided result handler
 * or retrieved via a subscription to the recognized event.
 *
 * @param keywordModel the keyword recognition model.
 * @param completionHandler the handler function called when keyword recognition has started.
 * @param outError error information.
 * @return a value indicating whether the request to start keyword recognition was received successfully. If NO,
 * additional information may available in outError.
 */
- (BOOL)startKeywordRecognitionAsync
                         :(nonnull SPXKeywordRecognitionModel *)keywordModel
        completionHandler:(nonnull SPXTranslationRecognitionAsyncCompletionHandler)completionHandler
                    error:(NSError * _Nullable * _Nullable)outError;

/**
 * Asynchronously begins a speech-to-text interaction with this recognizer
 * and immediately returns execution to the calling thread.
 * This interaction will use the provided keyword model to listen for a keyword indefinitely,
 * during which audio is not sent to the speech service and all processing is performed locally.
 * When a keyword is recognized, TranslationRecognizer will automatically connect to the speech service
 * and begin sending audio data from just before the keyword.
 * When received, speech-to-text results may be processed by the provided result handler
 * or retrieved via a subscription to the recognized event.
 *
 * @param keywordModel the keyword recognition model.
 * @param completionHandler the handler function called when keyword recognition has started.
 */
- (void)startKeywordRecognitionAsync
                         :(nonnull SPXKeywordRecognitionModel *)keywordModel
        completionHandler:(nonnull SPXTranslationRecognitionAsyncCompletionHandler)completionHandler
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Stops any active keyword recognition.
 *
 * @param outError error information.
 * @return a value indicating whether keyword recognition was stopped successfully. If NO, additional information may
 * be available in outError.
 */
- (BOOL)stopKeywordRecognition:(NSError * _Nullable * _Nullable)outError;

/**
 * Stops any active keyword recognition.
 */
- (void)stopKeywordRecognition
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Stops any active keyword recognition.
 *
 * @param completionHandler the handler function called when keyword recognition has stopped.
 * @param outError error information.
 * @return a value indicating whether the request to stop was received successfully. If NO, additional error
 * information may be available in outError.
 */
- (BOOL)stopKeywordRecognitionAsync
             :(nonnull SPXTranslationRecognitionAsyncCompletionHandler)completionHandler
        error:(NSError * _Nullable * _Nullable)outError;

/**
 * Stops any active keyword recognition.
 *
 * @param completionHandler the handler function called when keyword recognition has stopped.
 */
- (void)stopKeywordRecognitionAsync:(nonnull SPXTranslationRecognitionAsyncCompletionHandler)completionHandler
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Subscribes to the Recognized event which indicates that a final result has been recognized.
 */
- (void)addRecognizedEventHandler:(nonnull SPXTranslationRecognitionEventHandler)eventHandler;

/**
 * Subscribes to the Recognizing event which indicates that an intermediate result has been recognized.
 */
- (void)addRecognizingEventHandler:(nonnull SPXTranslationRecognitionEventHandler)eventHandler;

/**
 * Subscribes to the Synthesizing event which indicates that a synthesis voice output has been received.
 */
- (void)addSynthesizingEventHandler:(nonnull SPXTranslationSynthesisEventHandler)eventHandler;

/**
 * Subscribes to the Canceled event which indicates that an error occurred during recognition.
 */
- (void)addCanceledEventHandler:(nonnull SPXTranslationRecognitionCanceledEventHandler)eventHandler;

/**
 * Adds a target language for translation.
 * 
 * Added in version 1.7.0.
 *
 * @param lang the language identifier in BCP-47 format.
 */
- (void)addTargetLanguage:(nonnull NSString *)lang;

/**
 * Removes a target language for translation.
 * 
 * Added in version 1.7.0.
 *
 * @param lang the language identifier in BCP-47 format.
 */
- (void)removeTargetLanguage:(nonnull NSString *)lang;

@end
