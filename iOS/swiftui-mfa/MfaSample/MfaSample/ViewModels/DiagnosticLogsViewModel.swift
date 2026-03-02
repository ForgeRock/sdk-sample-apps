//
//  DiagnosticLogsViewModel.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Combine
import UIKit

/// ViewModel for displaying and managing diagnostic logs.
@MainActor
class DiagnosticLogsViewModel: ObservableObject {
    // MARK: - Dependencies
    private let logger = DiagnosticLogger.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State
    @Published var logs: [LogEntry] = []
    @Published var selectedFilter: LogFilter = .all
    @Published var searchText = ""
    @Published var showClearConfirmation = false

    // MARK: - Computed Properties
    var filteredLogs: [LogEntry] {
        var result = logs

        // Apply level filter
        switch selectedFilter {
        case .all:
            break
        case .debug:
            result = result.filter { $0.level == .debug }
        case .info:
            result = result.filter { $0.level == .info }
        case .warning:
            result = result.filter { $0.level == .warning }
        case .error:
            result = result.filter { $0.level == .error }
        }

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { log in
                log.message.localizedCaseInsensitiveContains(searchText) ||
                log.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result.reversed() // Show newest first
    }

    var logCount: String {
        "\(filteredLogs.count) / \(logs.count)"
    }

    // MARK: - Initialization
    init() {
        // Observe logger changes
        logger.$logs
            .assign(to: &$logs)
    }

    // MARK: - Actions
    /// Exports logs to share sheet
    func shareLog() -> String {
        logger.exportLogs()
    }

    /// Clears all logs
    func clearLogs() {
        logger.clearLogs()
    }

    // MARK: - Filter Enum
    enum LogFilter: String, CaseIterable {
        case all = "All"
        case debug = "Debug"
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
    }
}
