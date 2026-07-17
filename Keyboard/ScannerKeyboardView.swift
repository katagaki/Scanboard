import SwiftUI
import UIKit

struct ScannerKeyboardView: View {

    var model: KeyboardModel
    let insertText: (String) -> Void
    let deleteBackward: () -> Void
    let openScanner: () -> Void
    let configureInputModeSwitchButton: (UIButton) -> Void

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            keyRow
                .padding(8)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if model.hasFullAccess {
            scanArea
        } else {
            statusMessage(
                icon: "lock.shield",
                title: "Keyboard.FullAccessRequired",
                message: "Keyboard.FullAccessMessage"
            )
        }
    }

    private var scanArea: some View {
        VStack(spacing: 8) {
            Button(action: openScanner) {
                HStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Keyboard.Scan")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(AccentKeyButtonStyle())
            .padding(.horizontal, 8)
            .padding(.top, 8)

            if model.recentScans.isEmpty {
                Spacer()
                Text("Keyboard.EmptyHint")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(model.recentScans.prefix(12)) { item in
                            Button {
                                insertText(item.value)
                            } label: {
                                Text(item.value)
                                    .font(.system(size: 16, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(KeyButtonStyle())
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
    }

    private func statusMessage(icon: String, title: LocalizedStringKey, message: LocalizedStringKey) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 24)
    }

    // MARK: - Key Row

    private var keyRow: some View {
        HStack(spacing: 6) {
            if model.needsInputModeSwitchKey {
                InputModeSwitchKey(configure: configureInputModeSwitchButton)
                    .frame(width: 46, height: 42)
                    .background(keyBackground(special: true))
            }

            Button {
                insertText(" ")
            } label: {
                Text("Keyboard.Space")
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
            }
            .buttonStyle(KeyButtonStyle())

            Button {
                deleteBackward()
            } label: {
                Image(systemName: "delete.left")
                    .font(.system(size: 17))
                    .frame(width: 46, height: 42)
            }
            .buttonStyle(KeyButtonStyle(isSpecial: true))

            Button {
                insertText("\n")
            } label: {
                Text("Keyboard.Return")
                    .font(.system(size: 16))
                    .frame(width: 88, height: 42)
            }
            .buttonStyle(KeyButtonStyle(isSpecial: true))
        }
    }
}

// MARK: - Key Styling

private enum KeyStyle {

    static let cornerRadius: CGFloat = 9

    /// Regular key fill, matching the system keyboard's letter keys.
    static let keyFill = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.30)
            : UIColor.white
    })

    /// Darker fill used by the system keyboard's function keys
    /// (shift, delete, globe, return).
    static let specialKeyFill = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.12)
            : UIColor(red: 172 / 255, green: 177 / 255, blue: 185 / 255, alpha: 1)
    })

    /// The hard 1pt bottom edge under every system key.
    static let edgeShadow = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 0.50)
            : UIColor(red: 137 / 255, green: 138 / 255, blue: 141 / 255, alpha: 1)
    })
}

private func keyBackground(special: Bool) -> some View {
    RoundedRectangle(cornerRadius: KeyStyle.cornerRadius)
        .fill(special ? KeyStyle.specialKeyFill : KeyStyle.keyFill)
        .background(keyBottomEdge)
}

/// The system keyboard's hard 1pt bottom edge, drawn as an explicit shape.
/// On iOS 27, `.shadow(radius: 0, y: 1)` renders as a soft halo around the
/// whole key instead of a hard edge, so the edge is drawn manually.
private var keyBottomEdge: some View {
    RoundedRectangle(cornerRadius: KeyStyle.cornerRadius)
        .offset(y: 1)
        .subtracting(RoundedRectangle(cornerRadius: KeyStyle.cornerRadius))
        .fill(KeyStyle.edgeShadow)
}

private struct KeyButtonStyle: ButtonStyle {

    var isSpecial = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.primary)
            // The system keyboard swaps the two key fills while pressed
            .background(keyBackground(special: isSpecial != configuration.isPressed))
    }
}

/// The same key treatment as the rest of the keyboard, filled with the
/// app's accent color, like the system keyboard's tinted return key.
private struct AccentKeyButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: KeyStyle.cornerRadius)
                    .fill(Color.accentColor)
                    .brightness(configuration.isPressed ? -0.12 : 0)
                    .background(keyBottomEdge)
            )
    }
}

// MARK: - Input Mode Switch (Globe) Key

private struct InputModeSwitchKey: UIViewRepresentable {

    let configure: (UIButton) -> Void

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "globe"), for: .normal)
        button.tintColor = .label
        configure(button)
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {}
}
