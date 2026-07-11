import Foundation

struct ScanHistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let value: String
    let date: Date

    init(value: String, date: Date = Date()) {
        self.id = UUID()
        self.value = value
        self.date = date
    }
}

/// Mirrors scan history into the shared App Group container so the
/// keyboard extension (which cannot use iCloud KVS or the camera) can read it.
enum SharedScanStore {

    static let appGroupID = "group.com.tsubuzaki.Scanboard"

    private static let storeKey = "ScanHistory"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func load() -> [ScanHistoryItem] {
        guard let data = defaults?.data(forKey: storeKey),
              let decoded = try? JSONDecoder().decode([ScanHistoryItem].self, from: data) else { return [] }
        return decoded
    }

    static func save(_ items: [ScanHistoryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults?.set(data, forKey: storeKey)
    }
}
