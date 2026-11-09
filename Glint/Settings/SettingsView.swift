import AppKit
import SwiftUI

struct SettingsView: View {
    let settings: AppSettings
    let permissions: PermissionCenter
    let launchAtLogin: LaunchAtLogin

    var body: some View {
        TabView {
            GeneralSettings(settings: settings, launchAtLogin: launchAtLogin)
                .tabItem { Label("General", systemImage: "gearshape") }
            CaptureSettings(settings: settings)
                .tabItem { Label("Capture", systemImage: "camera.viewfinder") }
            RecordingSettings(settings: settings)
                .tabItem { Label("Recording", systemImage: "record.circle") }
            ConverterSettings(settings: settings)
                .tabItem { Label("Converter", systemImage: "arrow.triangle.2.circlepath") }
            ShortcutsSettings()
                .tabItem { Label("Shortcuts", systemImage: "command") }
            PermissionsSettings(permissions: permissions)
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
        }
        .padding(.top, 8)
        .frame(width: 640, height: 500)
    }
}

/// Marks settings that are saved now but have no feature to act on them yet.
private struct TakesEffect: View {
    let phase: Int
    var body: some View {
        Text("Saved now. Takes effect when this feature arrives in Phase \(phase).")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

private struct GeneralSettings: View {
    @Bindable var settings: AppSettings
    let launchAtLogin: LaunchAtLogin

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setEnabled($0) }
                ))
                if launchAtLogin.needsApproval {
                    LabeledContent("macOS needs you to approve this in Login Items.") {
                        Button("Open Login Items") { launchAtLogin.openLoginItemsSettings() }
                    }
                }
                if let error = launchAtLogin.errorMessage {
                    Text("Couldn’t change this: \(error)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Toggle("Show icon in the Dock", isOn: $settings.showDockIcon)
                    .onChange(of: settings.showDockIcon) { _, visible in
                        DockIcon.apply(visible: visible)
                    }
            }
            Section {
                Toggle("Play sound effects", isOn: $settings.soundEffectsEnabled)
                TakesEffect(phase: 2)
            }
            Section {
                LabeledContent("Version", value: AppInfo.version)
            }
        }
        .formStyle(.grouped)
    }
}

private struct CaptureSettings: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                FolderPicker(title: "Save screenshots to", folder: $settings.saveFolder)
                Picker("Image format", selection: $settings.imageFormat) {
                    ForEach(CaptureImageFormat.allCases) { Text($0.title).tag($0) }
                }
                Picker("After capture", selection: $settings.afterCapture) {
                    ForEach(AfterCaptureAction.allCases) { Text($0.title).tag($0) }
                }
            }
            Section {
                TextField("File name", text: $settings.fileNameTemplate)
                LabeledContent("Preview") {
                    Text(previewName)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                Text("You can use {date} and {time}.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section { TakesEffect(phase: 2) }
        }
        .formStyle(.grouped)
    }

    private var previewName: String {
        "\(FileNameTemplate.render(settings.fileNameTemplate, date: .now)).\(settings.imageFormat.rawValue)"
    }
}

private struct RecordingSettings: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Picker("Codec", selection: $settings.videoCodec) {
                    ForEach(VideoCodec.allCases) { Text($0.title).tag($0) }
                }
                Picker("Quality", selection: $settings.videoQuality) {
                    ForEach(VideoQuality.allCases) { Text($0.title).tag($0) }
                }
                Picker("Frame rate", selection: $settings.videoFPS) {
                    Text("30 FPS").tag(30)
                    Text("60 FPS").tag(60)
                }
            }
            Section { TakesEffect(phase: 3) }
        }
        .formStyle(.grouped)
    }
}

private struct ConverterSettings: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Picker("Save converted files", selection: $settings.converterOutput) {
                    ForEach(ConverterOutputLocation.allCases) { Text($0.title).tag($0) }
                }
                if settings.converterOutput == .customFolder {
                    FolderPicker(title: "Folder", folder: $settings.converterFolder)
                }
                Picker("If the file already exists", selection: $settings.overwriteRule) {
                    ForEach(OverwriteRule.allCases) { Text($0.title).tag($0) }
                }
                TakesEffect(phase: 9)
            }
            Section {
                Picker("Action Wheel modifier", selection: $settings.wheelModifier) {
                    ForEach(WheelModifier.allCases) { Text($0.title).tag($0) }
                }
                TakesEffect(phase: 10)
            }
        }
        .formStyle(.grouped)
    }
}

private struct ShortcutsSettings: View {
    var body: some View {
        ContentUnavailableView(
            "No shortcuts yet",
            systemImage: "command",
            description: Text("Global shortcuts arrive with the features they trigger, starting in Phase 2.")
        )
    }
}

private struct PermissionsSettings: View {
    let permissions: PermissionCenter

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(PermissionKind.allCases) { kind in
                    PermissionRow(kind: kind, permissions: permissions)
                }
            }
            .padding(20)
        }
        .task { await permissions.watch() }
    }
}

private struct FolderPicker: View {
    let title: String
    @Binding var folder: URL

    var body: some View {
        LabeledContent(title) {
            HStack {
                Text(folder.path(percentEncoded: false).replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Button("Choose…", action: choose)
            }
        }
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.directoryURL = folder
        if panel.runModal() == .OK, let url = panel.url {
            folder = url
        }
    }
}
