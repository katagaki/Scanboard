// ContentView.swift
// Routes between setup (camera not authorized) and scanner.

import SwiftUI
import AVFoundation

struct ContentView: View {

    @Binding var showScanner: Bool

    var body: some View {
        Group {
            if AVCaptureDevice.authorizationStatus(for: .video) == .authorized || showScanner {
                ScannerView()
            } else {
                SetupFlowView(onReady: {
                    showScanner = true
                })
            }
        }
        .animation(.spring(response: 0.4), value: showScanner)
    }
}
