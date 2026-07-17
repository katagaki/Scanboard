import SwiftUI

@main
struct StockRoomApp: App {
    var body: some Scene {
        WindowGroup {
            ReceiveView()
        }
    }
}

struct ReceiveView: View {

    @State private var itemTag = ""
    @FocusState private var tagFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Receive Item") {
                    TextField("Scan or enter item tag", text: $itemTag)
                        .font(.system(.body, design: .monospaced))
                        .focused($tagFocused)
                    LabeledContent("Location", value: "Bin A47 · Shelf 3")
                    LabeledContent("Quantity", value: "24")
                }
                Section("Received Today") {
                    row("PLT-00871-RECV", "10:12")
                    row("BIN-A47-S03", "9:58")
                    row("CASE-2261-OUT", "9:41")
                }
            }
            .navigationTitle("Receiving")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {}
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                tagFocused = true
            }
        }
    }

    private func row(_ tag: String, _ time: String) -> some View {
        HStack {
            Text(tag)
                .font(.system(.subheadline, design: .monospaced))
            Spacer()
            Text(time)
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
    }
}
