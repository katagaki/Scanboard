import SwiftUI

struct ScanHistorySheet: View {

    var store: ScanHistoryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.value)
                            .font(.system(.body, design: .monospaced))
                        Text(item.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.deleteItem(item)
                        } label: {
                            Label("History.Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .overlay {
                if store.items.isEmpty {
                    ContentUnavailableView("History.Empty",
                                           systemImage: "barcode.viewfinder")
                }
            }
            .navigationTitle("History.Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        dismiss()
                    }
                }
            }
        }
    }
}
