import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents

@main
struct ScanboardWidgetBundle: WidgetBundle {
    var body: some Widget {
        ScanboardLiveActivity()
        ScanboardControlWidget()
        ScanboardLockScreenWidget()
    }
}

struct ScanboardLiveActivity: Widget {

    private let deepLink = URL(string: "scanboard://scan")!

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ScanboardActivityAttributes.self) { context in
            // Lock Screen banner
            HStack(spacing: 12) {
                Image(systemName: "barcode.viewfinder")
                    .font(.title2)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("App.Name")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("LiveActivity.TapToScan")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding()
            .activityBackgroundTint(.clear)
            .widgetURL(deepLink)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.title2)
                        .padding(.top, 12)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("App.Name")
                        .font(.headline)
                        .padding(.top, 12)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text("LiveActivity.TapToScan")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let lastItem = context.state.lastScannedItem {
                            Text(lastItem)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "barcode.viewfinder")
            } compactTrailing: {
                Text("LiveActivity.Scan")
                    .font(.caption)
            } minimal: {
                Image(systemName: "barcode.viewfinder")
            }
            .widgetURL(deepLink)
        }
    }
}
