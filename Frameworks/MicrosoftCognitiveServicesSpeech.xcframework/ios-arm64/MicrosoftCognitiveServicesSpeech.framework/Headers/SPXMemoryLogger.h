///
// Copyright (c) Microsoft. All rights reserved.
// See https://aka.ms/csspeech/license for the full license information.
//

#import "SPXFoundation.h"
#import "SPXSpeechEnums.h"

/**
 * Class with static methods to control SDK logging into an in-memory buffer.
 * Turning on logging while running your Speech SDK scenario provides
 * detailed information from the SDK's core native components. If you
 * report an issue to Microsoft, you may be asked to provide logs to help
 * Microsoft diagnose the issue. Your application should not take dependency
 * on particular log strings, as they may change from one SDK release to another
 * without notice.
 * SPXMemoryLogger is designed for the case where you want to get access to logs
 * that were taken in the short duration before some unexpected event happens.
 * For example, if you are running a Speech Recognizer, you may want to dump the SPXMemoryLogger
 * after getting an event indicating recognition was canceled due to some error.
 * The size of the memory buffer is fixed at 2MB and cannot be changed. This is
 * a "ring" buffer, that is, new log strings written replace the oldest ones
 * in the buffer.
 * Added in version 1.43.0
 *
 * Memory logging is a process wide construct. That means that if (for example)
 * you have multiple speech recognizer objects running in parallel, there will be one
 * memory buffer containing interleaved logs from all recognizers. You cannot get a
 * separate logs for each recognizer.
 */
SPX_EXPORT
@interface SPXMemoryLogger : NSObject

/**
 * Starts logging into the internal memory buffer.
 */
+ (void)start;

/**
 * Stops logging into the internal memory buffer.
 */
+ (void)stop;

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
 * Writes the content of the whole memory buffer to the specified file.
 * It does not block other SDK threads from continuing to log into the buffer.
 * 
 * @param path Path to a log file on local disk.
 * @remarks This does not reset (clear) the memory buffer.
 */
+ (void)dumpToFile:(nonnull NSString *)path
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Writes the content of the whole memory buffer to the specified file.
 * It does not block other SDK threads from continuing to log into the buffer.
 * 
 * @param path Path to a log file on local disk.
 * @param outError The error information.
 * @remarks This does not reset (clear) the memory buffer.
 */
+ (void)dumpToFile:(nonnull NSString *)path error:(NSError * _Nullable * _Nullable)outError;

/**
 * Writes the content of the whole memory buffer to the specified output stream.
 * It does not block other SDK threads from continuing to log into the buffer.
 * 
 * @param outputStream The output stream to write to.
 * @remarks This does not reset (clear) the memory buffer.
 */
+ (void)dumpToOutputStream:(nonnull NSOutputStream *)outputStream
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Writes the content of the whole memory buffer to the specified output stream.
 * It does not block other SDK threads from continuing to log into the buffer.
 * 
 * @param outputStream The output stream to write to.
 * @param outError The error information.
 * @remarks This does not reset (clear) the memory buffer.
 */
+ (void)dumpToOutputStream:(nonnull NSOutputStream *)outputStream error:(NSError * _Nullable * _Nullable)outError;

/**
 * Returns the content of the whole memory buffer as an array of strings.
 * It does not block other SDK threads from continuing to log into the buffer.
 * 
 * @returns An array with the contents of the memory buffer copied into it.
 * @remarks This does not reset (clear) the memory buffer.
 */
+ (nullable NSArray<NSString *> *)dumpToNSArray
NS_SWIFT_UNAVAILABLE("Use the method with Swift-compatible error handling.");

/**
 * Returns the content of the whole memory buffer as an array of strings.
 * It does not block other SDK threads from continuing to log into the buffer.
 * 
 * @returns An array with the contents of the memory buffer copied into it.
 * @param outError The error information.
 * @remarks This does not reset (clear) the memory buffer.
 */
+ (nullable NSArray<NSString *> *)dumpToNSArray:(NSError * _Nullable * _Nullable)outError;

/**
 * Sets the level of the messages to be captured by the logger.
 * 
 * @param level Maximum level of detail to be captured by the logger.
 */
+ (void)setLevel:(SPXLogLevel)level;

@end