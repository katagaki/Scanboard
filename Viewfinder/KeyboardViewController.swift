// KeyboardViewController.swift  (Keyboard Extension target)

import UIKit
import AVFoundation
import AudioToolbox

public class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    private var captureSession: AVCaptureSession?
    private var scannerView: BarcodeScannerView!
    private var isSessionRunning = false
    private var needsCameraStart = false
    private let sessionQueue = DispatchQueue(label: "com.tsubuzaki.Scanboard.sessionQueue")
    private let ciContext = CIContext()

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        if let shared = UserDefaults(suiteName: "group.com.tsubuzaki.Scanboard") {
            shared.set(hasFullAccess, forKey: "hasFullAccess")
        }

        setupScannerView()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Defer camera start until layout has happened so the preview layer
        // gets a non-zero frame.
        needsCameraStart = true
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // By viewDidAppear, the view hierarchy has been laid out at least once.
        if needsCameraStart {
            needsCameraStart = false
            checkCameraPermissionAndStart()
        }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopSession()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
            // Keyboard extensions cannot present the system permission dialog.
            // Direct the user to open the main app where the prompt can appear.
            scannerView.showError("Open the Scanboard app to grant camera access.")
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

        // Metadata output for barcode detection.
        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else { return }
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: .main)

        metadataOutput.metadataObjectTypes = [
            .code128, .code39, .code93, .itf14,
            .ean13, .ean8, .upce,
            .pdf417, .qr, .dataMatrix
        ]

        // Video data output for the viewfinder.
        // AVCaptureVideoPreviewLayer does not render inside keyboard
        // extensions, so we grab frames manually and display them in a
        // UIImageView instead.
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

        captureSession = session

        // Observe session lifecycle notifications so we can recover from
        // system interruptions (common in keyboard extensions).
        NotificationCenter.default.addObserver(
            self, selector: #selector(sessionWasInterrupted),
            name: .AVCaptureSessionWasInterrupted, object: session)
        NotificationCenter.default.addObserver(
            self, selector: #selector(sessionInterruptionEnded),
            name: .AVCaptureSessionInterruptionEnded, object: session)
        NotificationCenter.default.addObserver(
            self, selector: #selector(sessionRuntimeError),
            name: .AVCaptureSessionRuntimeError, object: session)

        startSession()
    }

    private func startSession() {
        guard let session = captureSession, !isSessionRunning else { return }
        isSessionRunning = true
        sessionQueue.async { [weak self] in
            session.startRunning()
            DispatchQueue.main.async {
                guard let self = self else { return }
                if session.isRunning {
                    self.scannerView.showScanning()
                } else {
                    self.isSessionRunning = false
                }
            }
        }
    }

    private func stopSession() {
        guard let session = captureSession, isSessionRunning else { return }
        isSessionRunning = false
        sessionQueue.async {
            session.stopRunning()
        }
    }

    // MARK: - Session Notifications

    @objc private func sessionWasInterrupted(_ notification: Notification) {
        isSessionRunning = false
    }

    @objc private func sessionInterruptionEnded(_ notification: Notification) {
        startSession()
    }

    @objc private func sessionRuntimeError(_ notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        isSessionRunning = false
        // Attempt to restart for media-services-reset errors; show message otherwise.
        if error.code == .mediaServicesWereReset {
            startSession()
        } else {
            scannerView.showError("Camera error: \(error.localizedDescription)")
        }
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

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension KeyboardViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
        DispatchQueue.main.async { [weak self] in
            self?.scannerView.updatePreview(image)
        }
    }
}
