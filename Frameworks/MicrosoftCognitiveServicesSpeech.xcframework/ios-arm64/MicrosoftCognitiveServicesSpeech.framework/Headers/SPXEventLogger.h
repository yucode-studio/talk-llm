///
// Copyright (c) Microsoft. All rights reserved.
// See https://aka.ms/csspeech/license for the full license information.
//

#import "SPXFoundation.h"
#import "SPXSpeechEnums.h"

/**
 * Class with static methods to control callback-based SDK logging.
 * Turning on logging while running your Speech SDK scenario provides
 * detailed information from the SDK's core native components. If you
 * report an issue to Microsoft, you may be asked to provide logs to help
 * Microsoft diagnose the issue. Your application should not take dependency
 * on particular log strings, as they may change from one SDK release to another
 * without notice.
 * Use SPXEventLogger when you want to get access to new log strings as soon
 * as they are available, and you need to further process them. For example,
 * integrating Speech SDK logs with your existing logging collection system.
 * Added in version 1.43.0
 *
 * Event logging is a process wide construct. That means that if (for example)
 * you have multiple speech recognizer objects running in parallel, you can only register
 * one callback function to receive interleaved logs from all recognizers. You cannot register
 * a separate callback for each recognizer.
 */
SPX_EXPORT
@interface SPXEventLogger : NSObject

typedef void (^SPXEventLoggerHandler)(NSString * _Nonnull);

/**
 * Registers a callback function that will be invoked for each new log message.
 * 
 * @param callback The callback function to call. Pass nil to stop the Event Logger.
 * @param outError The error information.
 * @remarks You can only register one callback function. This call will happen on a working thread of the SDK,
 * so the log string should be copied somewhere for further processing by another thread, and the function should return immediately.
 * No heavy processing or network calls should be done in this callback function.
 */
+ (void)setCallback:(nullable SPXEventLoggerHandler)callback error:(NSError * _Nullable * _Nullable)outError;

/**
 * Registers a callback function that will be invoked for each new log message.
 * 
 * @param callback The callback function to call. Pass nil to stop the Event Logger.
 * @remarks You can only register one callback function. This call will happen on a working thread of the SDK,
 * so the log string should be copied somewhere for further processing by another thread, and the function should return immediately.
 * No heavy processing or network calls should be done in this callback function.
 */
+ (void)setCallback:(nullable SPXEventLoggerHandler)callback
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Sets or clears the filters that apply to file logging.
 * 
 * @param filters Filters to use, or nil or an empty list to remove previously set filters.
 * @param outError The error information.
 */
+ (void)setFilters:(nullable NSArray<NSString *> *)filters error:(NSError * _Nullable * _Nullable)outError;

/**
 * Sets or clears the filters that apply to file logging.
 * 
 * @param filters Filters to use, or nil or an empty list to remove previously set filters.
 */
+ (void)setFilters:(nullable NSArray<NSString *> *)filters
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

 /**
 * Sets the level of the messages to be captured by the logger.
 * 
 * @param level Maximum level of detail to be captured by the logger.
 */
+ (void)setLevel:(SPXLogLevel)level;

@end