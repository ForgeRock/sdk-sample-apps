// Core/Configuration/AppConfiguration.swift
import Foundation
import PingOneMFA

@MainActor
class AppConfiguration: ObservableObject {
    static let shared = AppConfiguration()

    @Published var isInitialized = false
    private var initTask: Task<Void, Never>?

    private init() {}

    func initialize() async {
        if initTask == nil {
            initTask = Task {
                do {
                    try await PingOneMFA.initialize(geo: .northAmerica)
                    isInitialized = true
                } catch {
                    initTask = nil
                    print("[AppConfiguration] Failed to initialize PingOneMFA: \(error.localizedDescription)")
                }
            }
        }
        await initTask?.value
    }
}
