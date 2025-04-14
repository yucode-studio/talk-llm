import Foundation
import os.log

public class DebugLogger {
    public enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case success = "SUCCESS"
        case warning = "WARNING"
        case error = "ERROR"
        case voice = "VOICE"

        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .success: return "✅"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .voice: return "🎤"
            }
        }

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .success: return .info
            case .warning: return .info
            case .error: return .error
            case .voice: return .info
            }
        }
    }

    public protocol LogHandler {
        func handleLog(level: LogLevel, tag: String, message: String, file: String, function: String, line: Int)
    }

    public class ConsoleLogHandler: LogHandler {
        public func handleLog(level: LogLevel, tag: String, message: String, file: String, function: String, line: Int) {
            let fileName = URL(fileURLWithPath: file).lastPathComponent
            let logMessage = "\(level.emoji) [\(tag)] \(message)"
            debugPrint("\(logMessage) [\(fileName):\(line) \(function)]")
        }
    }

    public class SystemLogHandler: LogHandler {
        private let logger: Logger

        public init(subsystem: String, category: String) {
            logger = Logger(subsystem: subsystem, category: category)
        }

        public func handleLog(level: LogLevel, tag: String, message: String, file _: String, function _: String, line _: Int) {
            logger.log(level: level.osLogType, "\(level.emoji) [\(tag)] \(message)")
        }
    }

    public static var isDebugMode = true

    public static var minimumLogLevel: LogLevel = .debug

    private let tag: String

    private var logHandlers: [LogHandler] = []

    private static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.example.app"

    public init(tag: String, useConsoleLogging: Bool = true, useSystemLogging: Bool = false) {
        self.tag = tag

        if useConsoleLogging {
            addLogHandler(ConsoleLogHandler())
        }

        if useSystemLogging {
            addLogHandler(SystemLogHandler(subsystem: Self.bundleIdentifier, category: tag))
        }
    }

    public func addLogHandler(_ handler: LogHandler) {
        logHandlers.append(handler)
    }

    public func log(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
            if level == .debug, !DebugLogger.isDebugMode {
                return
            }

            if level.rawValue < DebugLogger.minimumLogLevel.rawValue {
                return
            }

            for handler in logHandlers {
                handler.handleLog(level: level, tag: tag, message: message, file: file, function: function, line: line)
            }
        #endif
    }

    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, file: file, function: function, line: line)
    }

    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }

    public func success(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.success, message, file: file, function: function, line: line)
    }

    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, file: file, function: function, line: line)
    }

    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, file: file, function: function, line: line)
    }

    public func voice(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.voice, message, file: file, function: function, line: line)
    }
}
