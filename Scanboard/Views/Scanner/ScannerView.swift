import SwiftUI
import AVFoundation
import UIKit
import Observation

// MARK: - Scanner View

struct ScannerView: View {

    @State private var session = AVCaptureSession()
    @State private var isScanning = false
    @State private var toastValue: String = ""
    @State private var toastVisible = false
    @State private var toastID = 0
    @State private var coordinator: ScannerCoordinator?
    @State private var showHistory = false
    @StateObject private var historyStore = ScanHistoryStore.shared

    var body: some View {
        ZStack {
            CameraPreviewView(session: session)
                .ignoresSafeArea()

            // Scan reticle
            if isScanning {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.glow, lineWidth: 3)
                    .shadow(color: .accent, radius: 2.0)
                    .shadow(color: .accent, radius: 5.0)
                    .frame(width: 260, height: 160)
                    .transition(.opacity)
            }

            // History button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .padding(10)
                    .glassEffect(.regular.interactive(), in: .circle)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
            }

            // Toast overlay
            VStack {
                Spacer()

                VStack(spacing: 8) {
                    Text(toastValue)
                        .font(.system(.title2, design: .monospaced, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Label("Scanner.CopiedToClipboard", systemImage: "checkmark.circle.fill")
                        .labelIconToTitleSpacing(4)
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .glassEffect(.regular, in: .rect(cornerRadius: 20))
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .offset(y: toastVisible ? 0 : 200)
            .opacity(toastVisible ? 1 : 0)
            .animation(.spring(response: 0.35), value: toastVisible)
        }
        .task(id: toastID) {
            guard toastVisible else { return }
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            toastVisible = false
        }
        .onAppear {
            configureSession()
            startScanning()
        }
        .onDisappear {
            stopSession()
        }
        .sheet(isPresented: $showHistory) {
            ScanHistorySheet(store: historyStore)
        }
    }

    // MARK: - Session Setup

    private func configureSession() {
        guard coordinator == nil else { return }

        let coord = ScannerCoordinator { value in
            UIPasteboard.general.string = value
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            historyStore.addScan(value)
            LiveActivityManager.updateLastScannedItem(value)

            toastValue = value
            toastVisible = true
            toastID += 1
        }
        coordinator = coord

        let session = self.session
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video) else {
            session.commitConfiguration()
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                session.commitConfiguration()
                return
            }
            session.addInput(input)
        } catch {
            session.commitConfiguration()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(coord, queue: .main)
        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes

        session.commitConfiguration()
    }

    private func startScanning() {
        isScanning = true
        let session = self.session
        if !session.isRunning {
            session.startRunning()
        }
    }

    private func stopSession() {
        isScanning = false
        let session = self.session
        if session.isRunning {
            session.stopRunning()
        }
    }
}

// MARK: - Coordinator

private final class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {

    private let onScan: @MainActor (String) -> Void
    private var lastScannedValue: String?
    private var cooldownWorkItem: DispatchWorkItem?

    init(onScan: @escaping @MainActor (String) -> Void) {
        self.onScan = onScan
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue, !value.isEmpty else { return }
        guard value != lastScannedValue else { return }

        lastScannedValue = value
        onScan(value)

        cooldownWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.lastScannedValue = nil
        }
        cooldownWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: item)
    }
}
