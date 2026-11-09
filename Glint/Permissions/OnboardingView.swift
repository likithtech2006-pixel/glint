import SwiftUI

/// First-launch welcome, and the Permissions window afterwards.
struct OnboardingView: View {
    let permissions: PermissionCenter
    let isFirstRun: Bool
    let onDone: () -> Void

    private var grantedCount: Int {
        PermissionKind.allCases.count - permissions.missing.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 28)
                .padding(.bottom, 20)

            VStack(spacing: 10) {
                ForEach(PermissionKind.allCases) { kind in
                    PermissionRow(kind: kind, permissions: permissions)
                }
            }
            .padding(.horizontal, 24)

            footer
                .padding(24)
        }
        .frame(width: 600)
        .task { await permissions.watch() }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkle")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.tint)
                .padding(.bottom, 4)
            Text(isFirstRun ? "Welcome to \(AppInfo.name)" : "Permissions")
                .font(.title.bold())
            Text("Everything stays on this Mac: no analytics, no uploads.\nAllow what you plan to use. You can change these any time.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footer: some View {
        HStack {
            Text("\(grantedCount) of \(PermissionKind.allCases.count) allowed")
                .font(.callout)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
            Spacer()
            Button(isFirstRun ? "Get Started" : "Done", action: onDone)
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
        }
    }
}

struct PermissionRow: View {
    let kind: PermissionKind
    let permissions: PermissionCenter

    private var status: PermissionStatus { permissions.status(of: kind) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: kind.symbolName)
                .font(.system(size: 16))
                .foregroundStyle(.tint)
                .frame(width: 34, height: 34)
                .background(.tint.opacity(0.12), in: .rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(kind.title).font(.headline)
                    StatusBadge(status: status)
                }
                Text(kind.explanation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if showsRelaunchHint {
                    Text("Already turned it on? \(AppInfo.name) has to relaunch before macOS applies it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            actions
        }
        .padding(12)
        .background(.quinary, in: .rect(cornerRadius: 10))
    }

    private var showsRelaunchHint: Bool {
        kind.needsRelaunchAfterGrant && status == .denied
    }

    @ViewBuilder
    private var actions: some View {
        VStack(alignment: .trailing, spacing: 6) {
            switch status {
            case .granted, .restricted:
                EmptyView()
            case .notDetermined:
                Button("Allow…") {
                    Task { await permissions.request(kind) }
                }
                settingsButton
            case .denied:
                settingsButton
                if showsRelaunchHint {
                    Button("Relaunch \(AppInfo.name)") { permissions.relaunchApp() }
                }
            }
        }
        .controlSize(.small)
        .fixedSize()
    }

    private var settingsButton: some View {
        Button("Open System Settings") { permissions.openSystemSettings(for: kind) }
    }
}

private struct StatusBadge: View {
    let status: PermissionStatus

    private var label: (text: String, symbol: String, color: Color) {
        switch status {
        case .granted: ("Allowed", "checkmark.circle.fill", .green)
        case .denied: ("Not allowed", "xmark.circle.fill", .orange)
        case .notDetermined: ("Not set up", "circle.dashed", .secondary)
        case .restricted: ("Blocked by admin", "lock.fill", .secondary)
        }
    }

    var body: some View {
        Label(label.text, systemImage: label.symbol)
            .font(.caption.weight(.medium))
            .foregroundStyle(label.color)
            .labelStyle(.titleAndIcon)
    }
}
