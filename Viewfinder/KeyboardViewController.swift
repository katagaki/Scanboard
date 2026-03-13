// KeyboardViewController.swift  (Keyboard Extension target)
// ─────────────────────────────────────────────────────────────
// Drop this file into your Keyboard Extension target.
// It writes a "hasFullAccess" flag to the shared App Group so the
// containing app's SetupViewModel can confirm Full Access is on.

import UIKit
import AVFoundation
import AudioToolbox

public class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var scannerView: BarcodeScannerView!
    private var isSessionRunning = false

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Write Full Access status to shared App Group so the containing app
        // can detect it. Change the suite name to match your App Group identifier.
        if let shared = UserDefaults(suiteName: "group.com.tsubuzaki.Scanboard") {
            shared.set(hasFullAccess, forKey: "hasFullAccess")
        }

        setupScannerView()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkCameraPermissionAndStart()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopSession()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = scannerView.previewContainer.bounds
    }

    // MARK: - UI Setup

    private func setupScannerView() {
        scannerView = BarcodeScannerView()
        scannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scannerView)

        NSLayoutConstraint.activate([
            scannerView.topAnchor.constraint(equalTo: view.topAnchor),
            scannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scannerView.heightAnchor.constraint(equalToConstant: 220)
        ])

        scannerView.onInsertTapped = { [weak self] text in
            self?.insertText(text)
        }
        scannerView.onRescanTapped = { [weak self] in
            self?.resumeScanning()
        }
    }

    // MARK: - Camera Permission

    private func checkCameraPermissionAndStart() {
        guard hasFullAccess else {
            scannerView.showError("Enable Full Access in Settings to use the camera.")
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            if captureSession != nil {
                startSession()
            } else {
                setupCaptureSession()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.setupCaptureSession() }
                    else { self?.scannerView.showPermissionDenied() }
                }
            }
        default:
            scannerView.showPermissionDenied()
        }
    }

    // MARK: - Capture Session

    private func setupCaptureSession() {
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video) else {
            scannerView.showError("No camera available")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else { return }
            session.addInput(input)
        } catch {
            scannerView.showError("Camera error: \(error.localizedDescription)")
            return
        }

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)

        // Warehouse-focused barcode formats
        output.metadataObjectTypes = [
            .code128, .code39, .code93, .itf14,
            .ean13, .ean8, .upce,
            .pdf417, .qr, .dataMatrix
        ]

        // Narrow rect of interest matches the horizontal reticle
        output.rectOfInterest = CGRect(x: 0.25, y: 0.1, width: 0.5, height: 0.8)

        captureSession = session

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = scannerView.previewContainer.bounds
        scannerView.previewContainer.layer.insertSublayer(preview, at: 0)
        previewLayer = preview

        startSession()
    }

    private func startSession() {
        guard let session = captureSession, !isSessionRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = true
                self?.scannerView.showScanning()
            }
        }
    }

    private func stopSession() {
        guard let session = captureSession, isSessionRunning else { return }
        session.stopRunning()
        isSessionRunning = false
    }

    private func resumeScanning() {
        scannerView.showScanning()
        startSession()
    }

    private func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension KeyboardViewController: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue, !value.isEmpty else { return }

        stopSession()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        scannerView.showResult(value, type: obj.type)
    }
}
