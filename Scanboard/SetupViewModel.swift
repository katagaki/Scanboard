// SetupViewModel.swift
// Tracks whether each setup step has been completed.

import SwiftUI
import UIKit
import AVFoundation
import Combine

// The bundle identifier of the keyboard extension.
private let keyboardBundleID = "com.tsubuzaki.Scanboard.Viewfinder"

// The App Group shared between the main app and the keyboard extension.
private let appGroupID = "group.com.tsubuzaki.Scanboard"

@MainActor
final class SetupViewModel: ObservableObject {

    @Published var cameraAuthorized: Bool = false
    @Published var keyboardEnabled: Bool = false
    @Published var fullAccessEnabled: Bool = false

    var allDone: Bool {
        cameraAuthorized && keyboardEnabled && fullAccessEnabled
    }

    init() {
        refresh()
    }

    /// Call this every time the app becomes active (user may have changed settings).
    func refresh() {
        checkCamera()
        checkKeyboard()
    }

    // MARK: - Camera

    private func checkCamera() {
        cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    func requestCamera() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraAuthorized = granted
            }
        }
    }

    // MARK: - Keyboard detection
    // iOS doesn't expose a public API to check if a specific keyboard extension
    // is installed. The accepted workaround is to check UserDefaults written by
    // the extension, or to look at UITextInputMode.activeInputModes.
    // We use the input-modes approach as it requires no shared container.

    private func checkKeyboard() {
        let modes = UITextInputMode.activeInputModes
        let ids   = modes.compactMap { $0.value(forKey: "identifier") as? String }

        // A keyboard extension is "enabled" if its bundle ID appears in activeInputModes.
        keyboardEnabled = ids.contains(where: { $0.contains(keyboardBundleID) })

        // Full access: the extension writes a flag to a shared App Group UserDefaults.
        // Key written by KeyboardViewController.viewDidLoad when hasFullAccess == true.
        if let shared = UserDefaults(suiteName: appGroupID) {
            fullAccessEnabled = shared.bool(forKey: "hasFullAccess")
        } else {
            fullAccessEnabled = false
        }
    }

    // MARK: - Deep link to Settings
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
