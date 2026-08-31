// Views/Navigation/AppNavigationCoordinator.swift
import SwiftUI
import Combine

@MainActor
class AppNavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var showScanner = false

    func dismissScanner() {
        showScanner = false
    }
}
