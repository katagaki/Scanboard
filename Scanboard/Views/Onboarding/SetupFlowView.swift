// SetupFlowView.swift
// Camera permission setup and Live Activity instructions.

import SwiftUI
import AVFoundation

struct SetupFlowView: View {
    @State private var cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    @State private var cameraDenied = AVCaptureDevice.authorizationStatus(for: .video) == .denied
    @Environment(\.scenePhase) private var scenePhase
    var onReady: () -> Void

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

                    if cameraAuthorized {
                        ReadyView(onReady: onReady)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        StepsView(
                            cameraAuthorized: cameraAuthorized,
                            cameraDenied: cameraDenied,
                            requestCamera: requestCamera,
                            openSettings: openSettings
                        )
                        .transition(.opacity)
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear { refresh() }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                withAnimation(.spring(response: 0.4)) {
                    refresh()
                }
            }
        }
        .animation(.spring(response: 0.5), value: cameraAuthorized)
    }

    private func refresh() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraAuthorized = status == .authorized
        cameraDenied = status == .denied
    }

    private func requestCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            cameraAuthorized = granted
            cameraDenied = !granted
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
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
                Text("App.Name")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .lineSpacing(2)
            }

            Text("Onboarding.Subtitle")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

            Divider()
                .background(Color.accentColor.opacity(0.4))
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Steps

private struct StepsView: View {
    let cameraAuthorized: Bool
    let cameraDenied: Bool
    let requestCamera: () -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            SectionLabel(text: "Onboarding.Setup")

            StepCard(
                title: "Onboarding.AllowCameraAccess",
                description: "Onboarding.CameraAccessDescription",
                isComplete: cameraAuthorized,
                action: cameraAuthorized ? nil : (cameraDenied ? openSettings : requestCamera),
                actionLabel: cameraDenied ? "Onboarding.OpenSettings" : "Onboarding.GrantCameraAccess"
            )
        }
    }
}

// MARK: - Step Card

private struct StepCard: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let isComplete: Bool
    let action: (() -> Void)?
    let actionLabel: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                StatusBadge(isComplete: isComplete)
            }
            .padding(16)

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                if let action = action, !isComplete {
                    Button(action: action) {
                        Text(actionLabel)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.accentColor, in: .rect(cornerRadius: 6))
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isComplete ? Color.accentColor.opacity(0.4) : Color(.separator),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let isComplete: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: isComplete ? "checkmark" : "circle")
                .font(.system(size: 10, weight: .bold))
            Text(isComplete ? "Onboarding.Done" : "Onboarding.Pending")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(isComplete ? Color.accentColor : Color(.tertiaryLabel))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isComplete ? Color.accentColor.opacity(0.1) : Color.clear, in: .rect(cornerRadius: 4))
    }
}

// MARK: - Ready View

private struct ReadyView: View {
    var onReady: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                Text("Onboarding.ReadyToScan")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Text("Onboarding.CameraAccessGranted")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Divider()

            SectionLabel(text: "Onboarding.HowItWorks")

            VStack(alignment: .leading, spacing: 10) {
                InstructionRow(icon: "dot.radiowaves.left.and.right",
                               text: "Onboarding.Instruction.LiveActivity")
                InstructionRow(icon: "hand.tap",
                               text: "Onboarding.Instruction.TapToOpen")
                InstructionRow(icon: "barcode.viewfinder",
                               text: "Onboarding.Instruction.PointCamera")
                InstructionRow(icon: "arrow.uturn.backward",
                               text: "Onboarding.Instruction.SwitchBack")
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator), lineWidth: 1)
            }

            Button(action: onReady) {
                Text("Onboarding.OpenScanner")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: .rect(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Helpers

private struct InstructionRow: View {
    let icon: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.accentColor)
                .frame(width: 18)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SectionLabel: View {
    let text: LocalizedStringKey
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 3, height: 12)
            Text(text)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.accentColor)
                .tracking(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

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
    SetupFlowView(onReady: {})
}
