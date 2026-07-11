import Foundation
import Observation

@MainActor
@Observable
final class KeyboardModel {

    var hasFullAccess = false
    var needsInputModeSwitchKey = false

    private(set) var recentScans: [ScanHistoryItem] = []

    @ObservationIgnored private let pendingRequestKey = "PendingScanRequestDate"

    /// How long a scan request stays eligible for auto-insertion.
    @ObservationIgnored private let pendingRequestTimeout: TimeInterval = 10 * 60

    func refresh() {
        guard hasFullAccess else { return }
        recentScans = SharedScanStore.load()
    }

    /// Called when the user taps the scan key, right before the main app opens.
    func markScanRequested() {
        UserDefaults.standard.set(Date(), forKey: pendingRequestKey)
    }

    /// Returns the value to auto-insert if a new scan arrived after the last
    /// scan request, consuming the request so it only inserts once.
    func consumePendingScan() -> String? {
        guard let requestDate = UserDefaults.standard.object(forKey: pendingRequestKey) as? Date else {
            return nil
        }
        guard Date().timeIntervalSince(requestDate) < pendingRequestTimeout else {
            UserDefaults.standard.removeObject(forKey: pendingRequestKey)
            return nil
        }
        guard let newest = recentScans.first, newest.date > requestDate else { return nil }
        UserDefaults.standard.removeObject(forKey: pendingRequestKey)
        return newest.value
    }
}
