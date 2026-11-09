import ApplicationServices
import AVFoundation
import CoreGraphics

/// The system calls behind PermissionCenter, separated so tests can substitute them.
protocol PermissionProbe: Sendable {
    func status(of kind: PermissionKind) -> PermissionStatus
    func request(_ kind: PermissionKind) async
}

struct SystemPermissionProbe: PermissionProbe {
    func status(of kind: PermissionKind) -> PermissionStatus {
        switch kind {
        case .microphone: captureStatus(for: .audio)
        case .camera: captureStatus(for: .video)
        case .screenRecording: yesNoStatus(CGPreflightScreenCaptureAccess(), kind)
        case .accessibility: yesNoStatus(AXIsProcessTrusted(), kind)
        }
    }

    func request(_ kind: PermissionKind) async {
        switch kind {
        case .microphone:
            _ = await AVCaptureDevice.requestAccess(for: .audio)
        case .camera:
            _ = await AVCaptureDevice.requestAccess(for: .video)
        case .screenRecording:
            markPrompted(kind)
            _ = CGRequestScreenCaptureAccess()
        case .accessibility:
            markPrompted(kind)
            // The literal value of kAXTrustedCheckOptionPrompt. The imported global
            // is a mutable var, which Swift 6 rejects as not concurrency-safe.
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
    }

    private func captureStatus(for mediaType: AVMediaType) -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized: .granted
        case .denied: .denied
        case .restricted: .restricted
        case .notDetermined: .notDetermined
        @unknown default: .denied
        }
    }

    /// Screen Recording and Accessibility only report yes or no. To tell "never
    /// asked" from "refused" we remember whether we've shown the system prompt.
    private func yesNoStatus(_ isGranted: Bool, _ kind: PermissionKind) -> PermissionStatus {
        if isGranted { return .granted }
        return UserDefaults.standard.bool(forKey: promptedKey(kind)) ? .denied : .notDetermined
    }

    private func markPrompted(_ kind: PermissionKind) {
        UserDefaults.standard.set(true, forKey: promptedKey(kind))
    }

    private func promptedKey(_ kind: PermissionKind) -> String {
        "permissions.prompted.\(kind.rawValue)"
    }
}
