// Models/AppError.swift
import Foundation

enum AppError: LocalizedError {
    case sdkNotInitialized
    case pairingFailed(String)
    case accountLoadFailed(String)
    case pushProcessingFailed(String)

    var errorDescription: String? {
        switch self {
        case .sdkNotInitialized:
            return "PingOneMFA SDK is not initialized."
        case .pairingFailed(let msg):
            return "Pairing failed: \(msg)"
        case .accountLoadFailed(let msg):
            return "Failed to load accounts: \(msg)"
        case .pushProcessingFailed(let msg):
            return "Failed to process push notification: \(msg)"
        }
    }
}
