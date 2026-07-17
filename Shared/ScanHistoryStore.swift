import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ScanHistoryStore {

    static let shared = ScanHistoryStore()

    private static let storeKey = "ScanHistory"
    private static let tombstonesKey = "ScanHistoryTombstones"
    private static let tombstoneLifetime: TimeInterval = 30 * 24 * 60 * 60

    private(set) var items: [ScanHistoryItem] = []

    /// IDs of deleted items with their deletion date, kept so a merge with
    /// another device's copy doesn't resurrect them. Pruned after 30 days.
    private var tombstones: [UUID: Date] = [:]

    private let kvStore = NSUbiquitousKeyValueStore.default

    private init() {
        mergeFromCloud()
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
        // scan date stays current for the keyboard's auto-insertion. Keeping
        // the same id means a later cloud merge sees it as the same item.
        if let first = items.first, first.value == value {
            items[0] = ScanHistoryItem(id: first.id, value: value)
            saveToCloud()
            return
        }
        let item = ScanHistoryItem(value: value)
        items.insert(item, at: 0)
        saveToCloud()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            tombstones[items[index].id] = Date()
        }
        items.remove(atOffsets: offsets)
        saveToCloud()
    }

    func deleteItem(_ item: ScanHistoryItem) {
        tombstones[item.id] = Date()
        items.removeAll { $0.id == item.id }
        saveToCloud()
    }

    // MARK: - Persistence

    private func saveToCloud() {
        pruneTombstones()
        if let data = try? JSONEncoder().encode(items) {
            kvStore.set(data, forKey: Self.storeKey)
        }
        if let data = try? JSONEncoder().encode(tombstones) {
            kvStore.set(data, forKey: Self.tombstonesKey)
        }
        kvStore.synchronize()
        SharedScanStore.save(items)
    }

    /// iCloud KVS is last-writer-wins on whole values, so replacing the local
    /// array with the cloud copy loses local scans whenever a stale snapshot
    /// arrives (initial sync, or another device writing concurrently).
    /// Instead, union the two copies by id — newer date wins — and drop
    /// anything either side has deleted.
    private func mergeFromCloud() {
        if let data = kvStore.data(forKey: Self.tombstonesKey),
           let cloudTombstones = try? JSONDecoder().decode([UUID: Date].self, from: data) {
            tombstones.merge(cloudTombstones) { max($0, $1) }
        }

        var cloudItems: [ScanHistoryItem] = []
        if let data = kvStore.data(forKey: Self.storeKey),
           let decoded = try? JSONDecoder().decode([ScanHistoryItem].self, from: data) {
            cloudItems = decoded
        }

        var merged: [UUID: ScanHistoryItem] = [:]
        for item in cloudItems + items where tombstones[item.id] == nil {
            if let existing = merged[item.id], existing.date >= item.date { continue }
            merged[item.id] = item
        }
        items = merged.values.sorted { $0.date > $1.date }
        SharedScanStore.save(items)

        // Write back only if the merge changed anything relative to the cloud
        // copy, so devices converge without ping-ponging notifications.
        if items != cloudItems {
            saveToCloud()
        }
    }

    private func pruneTombstones() {
        let cutoff = Date().addingTimeInterval(-Self.tombstoneLifetime)
        tombstones = tombstones.filter { $0.value > cutoff }
    }

    @objc private func cloudDidChange(_ notification: Notification) {
        Task { @MainActor in
            mergeFromCloud()
        }
    }
}
