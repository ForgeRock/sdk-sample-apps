//
//  DiagnosticLogsScreen.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// Screen for viewing and exporting diagnostic logs.
struct DiagnosticLogsScreen: View {
    @StateObject private var viewModel = DiagnosticLogsViewModel()
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Filter Picker
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(DiagnosticLogsViewModel.LogFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search logs...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)

                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)

            // Log Count
            HStack {
                Text("Showing \(viewModel.logCount) logs")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Logs List
            if viewModel.filteredLogs.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No Logs",
                    message: viewModel.searchText.isEmpty ? "No diagnostic logs to display." : "No logs match your search.",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                List {
                    ForEach(viewModel.filteredLogs) { log in
                        LogEntryRow(entry: log)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Diagnostic Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Label("Export Logs", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive, action: {
                        viewModel.showClearConfirmation = true
                    }) {
                        Label("Clear Logs", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [viewModel.shareLog()])
        }
        .confirmationDialog("Clear Logs", isPresented: $viewModel.showClearConfirmation) {
            Button("Clear All Logs", role: .destructive) {
                viewModel.clearLogs()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to clear all diagnostic logs?")
        }
    }
}

// MARK: - Log Entry Row
private struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: entry.level.icon)
                    .font(.caption)
                    .foregroundColor(levelColor)

                Text(entry.level.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(levelColor)

                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(entry.category)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Message
            Text(entry.message)
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    private var levelColor: Color {
        switch entry.level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: entry.timestamp)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        DiagnosticLogsScreen()
    }
}
