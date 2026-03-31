import SwiftUI
import AVFoundation
import LockedCameraCapture
import UIKit

struct CaptureView: View {

    let captureSession: LockedCameraCaptureSession

    @State private var avSession = AVCaptureSession()
    @State private var coordinator: CaptureCoordinator?
    @State private var scannedValue: String?

    var body: some View {
        ZStack {
            CapturePreviewView(session: avSession)
                .ignoresSafeArea()

            // Scan reticle
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.white, lineWidth: 2)
                .frame(width: 260, height: 160)

            // Scanned value overlay
            if let scannedValue {
                VStack {
                    Spacer()

                    VStack(spacing: 8) {
                        Text(scannedValue)
                            .font(.system(.title2, design: .monospaced, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.horizontal)

                        Label("Scanner.CopiedToClipboard", systemImage: "checkmark.circle.fill")
                            .labelIconToTitleSpacing(4)
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: scannedValue)
        .onAppear {
            configureSession()
        }
        .onDisappear {
            if avSession.isRunning {
                avSession.stopRunning()
            }
        }
    }

    private func configureSession() {
        guard coordinator == nil else { return }

        let coord = CaptureCoordinator { value in
            UIPasteboard.general.string = value
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            scannedValue = value
        }
        coordinator = coord

        avSession.beginConfiguration()
        avSession.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video) else {
            avSession.commitConfiguration()
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard avSession.canAddInput(input) else {
                avSession.commitConfiguration()
                return
            }
            avSession.addInput(input)
        } catch {
            avSession.commitConfiguration()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        guard avSession.canAddOutput(metadataOutput) else {
            avSession.commitConfiguration()
            return
        }
        avSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(coord, queue: .main)
        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes

        avSession.commitConfiguration()
        avSession.startRunning()
    }
}

// MARK: - Camera Preview

private struct CapturePreviewView: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Coordinator

private final class CaptureCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {

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
