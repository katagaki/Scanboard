import AVFoundation
import Observation
import UIKit

@MainActor
@Observable
final class KeyboardScanner {

    enum CameraState: Equatable {
        case idle
        case needsFullAccess
        case needsCameraPermission
        case cameraDenied
        case cameraUnavailable
        case scanning
    }

    private(set) var state: CameraState = .idle
    private(set) var lastScannedValue: String?
    private(set) var scanCount = 0

    var hasFullAccess = false
    var needsInputModeSwitchKey = false
    var onScan: ((String) -> Void)?

    let session = AVCaptureSession()

    @ObservationIgnored private var isConfigured = false
    @ObservationIgnored private var coordinator: ScanCoordinator?

    // MARK: - Lifecycle

    func start() {
        guard hasFullAccess else {
            state = .needsFullAccess
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            state = .needsCameraPermission
        default:
            state = .cameraDenied
        }
    }

    func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if granted {
                    self.configureAndRun()
                } else {
                    self.state = .cameraDenied
                }
            }
        }
    }

    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
        if state == .scanning {
            state = .idle
        }
    }

    // MARK: - Session Setup

    private func configureAndRun() {
        guard configureIfNeeded() else {
            state = .cameraUnavailable
            return
        }
        if !session.isRunning {
            session.startRunning()
        }
        state = .scanning
    }

    private func configureIfNeeded() -> Bool {
        if isConfigured { return true }

        let coord = ScanCoordinator { [weak self] value in
            guard let self else { return }
            self.lastScannedValue = value
            self.scanCount += 1
            self.onScan?(value)
        }
        coordinator = coord

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .hd1280x720

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return false }
        session.addInput(input)

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else {
            session.removeInput(input)
            return false
        }
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(coord, queue: .main)
        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes

        isConfigured = true
        return true
    }
}

// MARK: - Coordinator

private final class ScanCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {

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
        Task { @MainActor in onScan(value) }

        cooldownWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.lastScannedValue = nil
        }
        cooldownWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: item)
    }
}
