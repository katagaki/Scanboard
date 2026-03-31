import LockedCameraCapture
import SwiftUI

@main
struct ScanboardCameraCaptureExtension: LockedCameraCaptureExtension {
    var body: some LockedCameraCaptureExtensionScene {
        LockedCameraCaptureUIScene { session in
            CaptureView(captureSession: session)
        }
    }
}
