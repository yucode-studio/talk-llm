///
// Copyright (c) Microsoft. All rights reserved.
// See https://aka.ms/csspeech/license for the full license information.
//

#import "SPXFoundation.h"
#import "SPXSpeechEnums.h"

/**
 * Class with static methods to control file-based SDK logging.
 * Turning on logging while running your Speech SDK scenario provides
 * detailed information from the SDK's core native components. If you
 * report an issue to Microsoft, you may be asked to provide logs to help
 * Microsoft diagnose the issue. Your application should not take dependency
 * on particular log strings, as they may change from one SDK release to another
 * without notice.
 * SPXFileLogger is the simplest logging solution and suitable for diagnosing
 * most on-device issues when running Speech SDK.
 * Added in version 1.43.0
 *
 * File logging is a process wide construct. That means that if (for example)
 * you have multiple speech recognizer objects running in parallel, there will be one
 * log file containing interleaved logs lines from all recognizers. You cannot get a
 * separate log file for each recognizer.
 */
SPX_EXPORT
@interface SPXFileLogger : NSObject

/**
 * Starts logging to a file.
 * 
 * @param path Path to a log file on local disk.
 * @param append If true, appends to existing log file. If false, creates a new log file.
 * @param outError The error information.
 */
+ (void)start:(nonnull NSString *)path append:(BOOL)append error:(NSError * _Nullable * _Nullable)outError;

/**
 * Starts logging to a file.
 * 
 * @param path Path to a log file on local disk.
 * @param append If true, appends to existing log file. If false, creates a new log file.
 */
+ (void)start:(nonnull NSString *)path append:(BOOL)append
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Starts logging to a file.
 * 
 * @param path Path to a log file on local disk.
 * @param outError The error information.
 */
+ (void)start:(nonnull NSString *)path error:(NSError * _Nullable * _Nullable)outError;

/**
 * Starts logging to a file.
 * 
 * @param path Path to a log file on local disk.
 */
+ (void)start:(nonnull NSString *)path
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Stops logging to a file.
 * 
 * @param outError The error information.
 */
+ (void)stop:(NSError * _Nullable * _Nullable)outError;

/**
 * Stops logging to a file.
 */
 + (void)stop
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