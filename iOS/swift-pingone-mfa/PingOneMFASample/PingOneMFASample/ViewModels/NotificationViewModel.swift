// ViewModels/NotificationViewModel.swift
import Foundation
import PingOneMFA

@MainActor
final class NotificationViewModel: ObservableObject {
    let notification: MFAPushNotification

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    @Published var isDenied = false

    init(notification: MFAPushNotification) {
        self.notification = notification
    }

    func approve(numberChallenge: Int? = nil) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await notification.approveNotification(authMethod: "user", numberChallenge: numberChallenge)
                showSuccessAlert = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func deny() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await notification.denyNotification()
                isDenied = true
                showSuccessAlert = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
