import Foundation
import Testing
@testable import Glint

private final class FakeProbe: PermissionProbe, @unchecked Sendable {
    var statuses: [PermissionKind: PermissionStatus]
    var onRequest: [PermissionKind: PermissionStatus] = [:]
    private(set) var requested: [PermissionKind] = []

    init(_ statuses: [PermissionKind: PermissionStatus]) {
        self.statuses = statuses
    }

    func status(of kind: PermissionKind) -> PermissionStatus {
        statuses[kind] ?? .notDetermined
    }

    func request(_ kind: PermissionKind) async {
        requested.append(kind)
        if let result = onRequest[kind] {
            statuses[kind] = result
        }
    }
}

@MainActor
struct PermissionCenterTests {
    @Test func reportsOnlyUngrantedAsMissing() {
        let center = PermissionCenter(probe: FakeProbe([
            .screenRecording: .granted,
            .microphone: .denied,
            .camera: .restricted,
            .accessibility: .granted,
        ]))
        #expect(center.missing == [.microphone, .camera])
    }

    @Test func refreshPicksUpChangesMadeInSystemSettings() {
        let probe = FakeProbe([.accessibility: .denied])
        let center = PermissionCenter(probe: probe)
        #expect(center.status(of: .accessibility) == .denied)

        probe.statuses[.accessibility] = .granted
        center.refresh()
        #expect(center.status(of: .accessibility) == .granted)
    }

    @Test func requestUpdatesStatus() async {
        let probe = FakeProbe([.microphone: .notDetermined])
        probe.onRequest[.microphone] = .granted
        let center = PermissionCenter(probe: probe)

        await center.request(.microphone)

        #expect(probe.requested == [.microphone])
        #expect(center.status(of: .microphone) == .granted)
    }

    @Test func gatePassesWithoutPromptingWhenGranted() {
        let center = PermissionCenter(probe: FakeProbe([.screenRecording: .granted]))
        #expect(PermissionGate(permissions: center).check([.screenRecording], for: "Test"))
    }

    @Test func gatePassesWhenNothingIsRequired() {
        let center = PermissionCenter(probe: FakeProbe([:]))
        #expect(PermissionGate(permissions: center).check([], for: "Test"))
    }
}
