import AVFoundation
import SwiftUI
import UIKit

struct ScannerKeyboardView: View {

    var scanner: KeyboardScanner
    let insertText: (String) -> Void
    let deleteBackward: () -> Void
    let configureInputModeSwitchButton: (UIButton) -> Void

    @State private var toastVisible = false

    var body: some View {
        VStack(spacing: 0) {
            cameraArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .clipped()

            keyRow
                .padding(8)
                .background(.thinMaterial)
        }
        .task(id: scanner.scanCount) {
            guard scanner.scanCount > 0 else { return }
            toastVisible = true
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            toastVisible = false
        }
    }

    // MARK: - Camera Area

    @ViewBuilder
    private var cameraArea: some View {
        switch scanner.state {
        case .idle:
            ProgressView()
                .tint(.white)
        case .scanning:
            ZStack {
                ScannerPreviewView(session: scanner.session)

                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.9), lineWidth: 2)
                    .frame(width: 200, height: 110)

                if toastVisible, let value = scanner.lastScannedValue {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(value)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .font(.system(.footnote, design: .monospaced, weight: .semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: .capsule)
                        .padding(.bottom, 10)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: toastVisible)
        case .needsFullAccess:
            statusMessage(
                icon: "lock.shield",
                title: "Full Access Required",
                message: "Turn on Allow Full Access for this keyboard in Settings > General > Keyboard > Keyboards to scan with the camera."
            )
        case .needsCameraPermission:
            VStack(spacing: 12) {
                statusMessage(
                    icon: "camera",
                    title: "Camera Access",
                    message: "Allow camera access to scan barcodes and QR codes."
                )
                Button("Enable Camera") {
                    scanner.requestCameraAccess()
                }
                .buttonStyle(.borderedProminent)
            }
        case .cameraDenied:
            statusMessage(
                icon: "video.slash",
                title: "Camera Access Denied",
                message: "Allow camera access in Settings > Privacy & Security > Camera."
            )
        case .cameraUnavailable:
            statusMessage(
                icon: "exclamationmark.triangle",
                title: "Camera Unavailable",
                message: "The camera could not be started."
            )
        }
    }

    private func statusMessage(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
    }

    // MARK: - Key Row

    private var keyRow: some View {
        HStack(spacing: 8) {
            if scanner.needsInputModeSwitchKey {
                InputModeSwitchKey(configure: configureInputModeSwitchButton)
                    .frame(width: 52, height: 40)
                    .background(keyBackground(pressed: false))
            }

            Button {
                insertText(" ")
            } label: {
                Text("space")
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .buttonStyle(KeyButtonStyle())

            Button {
                deleteBackward()
            } label: {
                Image(systemName: "delete.left")
                    .font(.system(size: 16))
                    .frame(width: 52, height: 40)
            }
            .buttonStyle(KeyButtonStyle())

            Button {
                insertText("\n")
            } label: {
                Text("return")
                    .font(.system(size: 15))
                    .frame(width: 76, height: 40)
            }
            .buttonStyle(KeyButtonStyle())
        }
    }
}

// MARK: - Key Styling

private func keyBackground(pressed: Bool) -> some View {
    RoundedRectangle(cornerRadius: 8)
        .fill(Color(uiColor: .systemBackground))
        .opacity(pressed ? 0.55 : 0.9)
}

private struct KeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.primary)
            .background(keyBackground(pressed: configuration.isPressed))
    }
}

// MARK: - Input Mode Switch (Globe) Key

private struct InputModeSwitchKey: UIViewRepresentable {

    let configure: (UIButton) -> Void

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "globe"), for: .normal)
        button.tintColor = .label
        configure(button)
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {}
}

// MARK: - Camera Preview

private struct ScannerPreviewView: UIViewRepresentable {

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
