import SwiftUI
import WidgetKit
import AppIntents

struct ScanboardLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.tsubuzaki.Scanboard.LockScreenWidget",
            provider: ScanboardLockScreenProvider()
        ) { _ in
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "barcode.viewfinder")
                    .font(.title)
                    .widgetAccentable()
            }
            .widgetURL(URL(string: "scanboard://scan"))
        }
        .configurationDisplayName("Widget.ScanBarcode")
        .description("Widget.ScanBarcodeDescription")
        .supportedFamilies([.accessoryCircular])
    }
}

struct ScanboardLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScanboardLockScreenEntry {
        ScanboardLockScreenEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ScanboardLockScreenEntry) -> Void) {
        completion(ScanboardLockScreenEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScanboardLockScreenEntry>) -> Void) {
        let entry = ScanboardLockScreenEntry(date: .now)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct ScanboardLockScreenEntry: TimelineEntry {
    let date: Date
}
