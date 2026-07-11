import Foundation
import Observation
import SwiftUI

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
        // Refresh consecutive duplicates instead of stacking them, so the
        // scan date stays current for the keyboard's auto-insertion.
        if items.first?.value == value {
            items[0] = ScanHistoryItem(value: value)
            saveToCloud()
            return
        }
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
        SharedScanStore.save(items)
    }

    private func loadFromCloud() {
        guard let data = kvStore.data(forKey: Self.storeKey),
              let decoded = try? JSONDecoder().decode([ScanHistoryItem].self, from: data) else { return }
        items = decoded
        SharedScanStore.save(items)
    }

    @objc private func cloudDidChange(_ notification: Notification) {
        Task { @MainActor in
            loadFromCloud()
        }
    }
}
