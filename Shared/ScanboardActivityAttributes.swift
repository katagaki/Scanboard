import ActivityKit

struct ScanboardActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var lastScannedItem: String?
    }
}
