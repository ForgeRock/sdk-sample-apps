//
//  DiagnosticLogger.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Combine
import os.log

/// Log entry representing a single diagnostic log message.
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let category: String
    let message: String

    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"

        var icon: String {
            switch self {
            case .debug: return "ladybug"
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            }
        }
    }
}

/// Service for capturing and managing diagnostic logs.
@MainActor
class DiagnosticLogger: ObservableObject {
    static let shared = DiagnosticLogger()

    // MARK: - Published State
    @Published private(set) var logs: [LogEntry] = []

    // MARK: - Properties
    private let maxLogEntries = 1000
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pingidentity.mfaexample", category: "Diagnostic")

    // MARK: - Initialization
    private init() {}

    // MARK: - Logging Methods
    /// Logs a debug message
    func debug(_ message: String, category: String = "General") {
        log(message, level: .debug, category: category)
        logger.debug("\(category): \(message)")
    }

    /// Logs an info message
    func info(_ message: String, category: String = "General") {
        log(message, level: .info, category: category)
        logger.info("\(category): \(message)")
    }

    /// Logs a warning message
    func warning(_ message: String, category: String = "General") {
        log(message, level: .warning, category: category)
        logger.warning("\(category): \(message)")
    }

    /// Logs an error message
    func error(_ message: String, category: String = "General") {
        log(message, level: .error, category: category)
        logger.error("\(category): \(message)")
    }

    /// Internal logging method
    private func log(_ message: String, level: LogEntry.LogLevel, category: String) {
        guard UserPreferences.shared.diagnosticLogging else {
            return
        }

        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message
        )

        logs.append(entry)

        // Trim logs if exceeding max entries
        if logs.count > maxLogEntries {
            logs.removeFirst(logs.count - maxLogEntries)
        }
    }

    // MARK: - Export Methods
    /// Exports all logs as a formatted string
    func exportLogs() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        var output = "MFA Example - Diagnostic Logs\n"
        output += "Generated: \(dateFormatter.string(from: Date()))\n"
        output += "Total Entries: \(logs.count)\n"
        output += String(repeating: "=", count: 80) + "\n\n"

        for entry in logs {
            let timestamp = dateFormatter.string(from: entry.timestamp)
            output += "[\(timestamp)] [\(entry.level.rawValue)] [\(entry.category)]\n"
            output += "\(entry.message)\n\n"
        }

        return output
    }

    /// Clears all logs
    func clearLogs() {
        logs.removeAll()
        info("Logs cleared", category: "DiagnosticLogger")
    }

    /// Gets logs filtered by level
    func logs(withLevel level: LogEntry.LogLevel) -> [LogEntry] {
        logs.filter { $0.level == level }
    }

    /// Gets logs filtered by category
    func logs(withCategory category: String) -> [LogEntry] {
        logs.filter { $0.category == category }
    }
}
