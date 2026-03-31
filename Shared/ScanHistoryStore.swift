import Foundation
import Observation
import SwiftUI

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

@MainActor
@Observable
final class ScanHistoryStore {

    static let shared = ScanHistoryStore()

    private static let storeKey = "ScanHistory"

    private(set) var items: [ScanHistoryItem] = []

    private let kvStore = NSUbiquitousKeyValueStore.default

    private init() {
        loadFromCloud()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvStore
        )
        kvStore.synchronize()
    }

    // MARK: - Public

    func addScan(_ value: String) {
        // Ignore consecutive duplicates
        if items.first?.value == value { return }
        let item = ScanHistoryItem(value: value)
        items.insert(item, at: 0)
        saveToCloud()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveToCloud()
    }

    func deleteItem(_ item: ScanHistoryItem) {
        items.removeAll { $0.id == item.id }
        saveToCloud()
    }

    // MARK: - Persistence

    private func saveToCloud() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        kvStore.set(data, forKey: Self.storeKey)
        kvStore.synchronize()
    }

    private func loadFromCloud() {
        guard let data = kvStore.data(forKey: Self.storeKey),
              let decoded = try? JSONDecoder().decode([ScanHistoryItem].self, from: data) else { return }
        items = decoded
    }

    @objc private func cloudDidChange(_ notification: Notification) {
        Task { @MainActor in
            loadFromCloud()
        }
    }
}
