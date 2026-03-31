import ActivityKit
import Foundation

enum LiveActivityManager {

    static var isActivityRunning: Bool {
        !Activity<ScanboardActivityAttributes>.activities.isEmpty
    }

    static func startActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard !isActivityRunning else { return }

        let attributes = ScanboardActivityAttributes()
        let state = ScanboardActivityAttributes.ContentState()
        let content = ActivityContent(state: state,
                                      staleDate: Date().addingTimeInterval(8 * 3600))
        do {
            _ = try Activity.request(attributes: attributes,
                                     content: content)
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    static func updateLastScannedItem(_ value: String) {
        let state = ScanboardActivityAttributes.ContentState(lastScannedItem: value)
        let content = ActivityContent(state: state,
                                      staleDate: Date().addingTimeInterval(8 * 3600))
        Task {
            for activity in Activity<ScanboardActivityAttributes>.activities {
                await activity.update(content)
            }
        }
    }

    static func endAllActivities() async {
        for activity in Activity<ScanboardActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
