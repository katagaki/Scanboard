import AppIntents

struct OpenScannerIntent: AppIntent {
    static var title: LocalizedStringResource = "Widget.OpenScanner"
    static var description: IntentDescription = "Widget.OpenScannerDescription"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
