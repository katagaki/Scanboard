import SwiftUI
import WidgetKit
import AppIntents

struct ScanboardControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.tsubuzaki.Scanboard.ScanControl") {
            ControlWidgetButton(action: OpenScannerIntent()) {
                Label("Widget.ScanBarcode", systemImage: "barcode.viewfinder")
            }
        }
        .displayName("Widget.ScanBarcode")
        .description("Widget.ScanBarcodeDescription")
    }
}
