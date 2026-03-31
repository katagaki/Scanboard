import SwiftUI
import WidgetKit
import AppIntents

struct ScanboardCameraControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.tsubuzaki.Scanboard.CameraControl") {
            ControlWidgetButton(action: OpenScannerIntent()) {
                Label("Widget.ScanBarcode", systemImage: "barcode.viewfinder")
            }
        }
        .displayName("Widget.ScanBarcode")
        .description("Widget.ScanBarcodeDescription")
    }
}
