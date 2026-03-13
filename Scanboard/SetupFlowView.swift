// SetupFlowView.swift
// Setup checklist and keyboard test area.

import SwiftUI

struct SetupFlowView: View {
    @StateObject private var vm = SetupViewModel()
    @State private var showTestField = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            GridPatternView()
                .opacity(0.07)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HeaderView()
                        .padding(.top, 56)
                        .padding(.bottom, 40)

                    if vm.allDone {
                        AllDoneView(showTestField: $showTestField)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        StepsView(vm: vm)
                            .transition(.opacity)
                    }

                    KeyboardTestArea()
                        .padding(.top, 32)

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear { vm.refresh() }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        ) { _ in
            withAnimation(.spring(response: 0.4)) {
                vm.refresh()
            }
        }
        .animation(.spring(response: 0.5), value: vm.allDone)
    }
}

// MARK: - Header

private struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.accentColor)
                Text("Scanboard")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineSpacing(2)
            }

            Divider()
                .background(Color.accentColor.opacity(0.4))
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Steps

private struct StepsView: View {
    @ObservedObject var vm: SetupViewModel

    var body: some View {
        VStack(spacing: 16) {
            SectionLabel(text: "SETUP CHECKLIST")

            StepCard(
                number: "01",
                title: "Allow Camera Access",
                description: "The keyboard needs your camera to scan barcodes. Tap below to grant access.",
                isComplete: vm.cameraAuthorized,
                action: vm.cameraAuthorized ? nil : { vm.requestCamera() },
                actionLabel: "Grant Camera Access",
                isOpenSettings: false
            )

            StepCard(
                number: "02",
                title: "Add the Keyboard",
                description: stepTwoDescription,
                isComplete: vm.keyboardEnabled,
                action: { vm.openSettings() },
                actionLabel: "Open Settings",
                isOpenSettings: true
            )

            if vm.keyboardEnabled {
                StepCard(
                    number: "03",
                    title: "Enable Full Access",
                    description: stepThreeDescription,
                    isComplete: vm.fullAccessEnabled,
                    action: { vm.openSettings() },
                    actionLabel: "Open Settings",
                    isOpenSettings: true
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if vm.keyboardEnabled && !vm.fullAccessEnabled {
                FullAccessWarningView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4), value: vm.keyboardEnabled)
    }

    private var stepTwoDescription: String {
"""
1. Tap "Open Settings" below
2. Go to General → Keyboard → Keyboards
3. Tap "Add New Keyboard…"
4. Select "Scan Keyboard" from the list
"""
    }

    private var stepThreeDescription: String {
"""
1. Go to Settings → General → Keyboard → Keyboards
2. Tap "Scan Keyboard"
3. Turn on "Allow Full Access"
4. Tap "Allow" on the confirmation prompt

Full Access is required for the camera to work inside the keyboard.
"""
    }
}

// MARK: - Step Card

private struct StepCard: View {
    let number: String
    let title: String
    let description: String
    let isComplete: Bool
    let action: (() -> Void)?
    let actionLabel: String
    let isOpenSettings: Bool

    @State private var pressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top bar
            HStack {
                Text(number)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(isComplete ? Color.accentColor : Color(.tertiaryLabel))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isComplete ? Color.accentColor : Color(.separator), lineWidth: 1)
                    )

                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                Spacer()

                StatusBadge(isComplete: isComplete)
            }
            .padding(16)

            Divider()

            // Body
            VStack(alignment: .leading, spacing: 14) {
                Text(description)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                if let action = action, !isComplete {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            if isOpenSettings {
                                Image(systemName: "gear")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            Text(actionLabel)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .cornerRadius(6)
                    }
                    .scaleEffect(pressed ? 0.97 : 1.0)
                    .animation(.spring(response: 0.2), value: pressed)
                }
            }
            .padding(16)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isComplete ? Color.accentColor.opacity(0.4) : Color(.separator),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let isComplete: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: isComplete ? "checkmark" : "circle")
                .font(.system(size: 10, weight: .bold))
            Text(isComplete ? "DONE" : "PENDING")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
        }
        .foregroundColor(isComplete ? Color.accentColor : Color(.tertiaryLabel))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isComplete ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Full Access Warning

private struct FullAccessWarningView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .foregroundColor(.accentColor)
                .font(.system(size: 14))
                .padding(.top, 1)

            Text("iOS displays a warning that keyboards with Full Access can log keystrokes. This app does not log or transmit any text — Full Access is only used to activate the camera.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - All Done

private struct AllDoneView: View {
    @Binding var showTestField: Bool

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                Text("KEYBOARD READY")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                Text("Scan Keyboard is installed and active.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Divider()

            SectionLabel(text: "TEST IT OUT")

            VStack(alignment: .leading, spacing: 8) {
                Text("Tap the field below, switch to Scan Keyboard, and point your camera at a barcode.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)

                TestInputField()
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator), lineWidth: 1)
            )

            HowToSwitchCard()
        }
    }
}

// MARK: - Test Input Field

private struct TestInputField: View {
    @State private var text = ""

    var body: some View {
        HStack {
            TextField("Scanned value appears here\u{2026}", text: $text)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.primary)
                .tint(.accentColor)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
        .padding(12)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - How to switch keyboard card

private struct HowToSwitchCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "SWITCHING KEYBOARDS")

            VStack(alignment: .leading, spacing: 10) {
                InstructionRow(icon: "globe", text: "Tap the globe icon on the system keyboard to cycle to Scan Keyboard")
                InstructionRow(icon: "hand.tap", text: "Or long-press the globe to pick Scan Keyboard directly from the list")
                InstructionRow(icon: "barcode.viewfinder", text: "Point your camera at a barcode — a green button will appear")
                InstructionRow(icon: "keyboard", text: "Tap the button to insert the scanned value into your text field")
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
    }
}

private struct InstructionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.accentColor)
                .frame(width: 18)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Section Label

private struct SectionLabel: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 3, height: 12)
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.accentColor)
                .tracking(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Keyboard Test Area

private struct KeyboardTestArea: View {
    @State private var singleLine = ""
    @State private var multiLine = ""
    @FocusState private var focusedField: TestField?

    private enum TestField {
        case singleLine, multiLine
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "KEYBOARD TEST")

            VStack(alignment: .leading, spacing: 14) {
                Text("Tap a field below, then switch to Scan Keyboard to test barcode scanning.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)

                // Single-line field
                VStack(alignment: .leading, spacing: 6) {
                    Text("SINGLE LINE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(.tertiaryLabel))
                        .tracking(1)

                    HStack {
                        TextField("Scan a barcode\u{2026}", text: $singleLine)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.primary)
                            .tint(.accentColor)
                            .focused($focusedField, equals: .singleLine)

                        if !singleLine.isEmpty {
                            Button {
                                singleLine = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                focusedField == .singleLine
                                    ? Color.accentColor
                                    : Color(.separator),
                                lineWidth: 1
                            )
                    )
                }

                // Multi-line field
                VStack(alignment: .leading, spacing: 6) {
                    Text("MULTI LINE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(.tertiaryLabel))
                        .tracking(1)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $multiLine)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.primary)
                            .tint(.accentColor)
                            .scrollContentBackground(.hidden)
                            .focused($focusedField, equals: .multiLine)
                            .frame(minHeight: 100)

                        if multiLine.isEmpty {
                            Text("Scan multiple barcodes\u{2026}")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color(.tertiaryLabel))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                focusedField == .multiLine
                                    ? Color.accentColor
                                    : Color(.separator),
                                lineWidth: 1
                            )
                    )
                }

                // Clear all button
                if !singleLine.isEmpty || !multiLine.isEmpty {
                    Button {
                        singleLine = ""
                        multiLine = ""
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Clear All")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                    }
                    .transition(.opacity)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: singleLine.isEmpty && multiLine.isEmpty)
        }
    }
}

// MARK: - Grid Pattern

private struct GridPatternView: View {
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 28
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            ctx.stroke(path, with: .color(.primary), lineWidth: 0.5)
        }
    }
}

#Preview {
    SetupFlowView()
}
