import AppKit

@main
@MainActor
enum GlintMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        // NSApplication holds its delegate weakly, so keep ours alive for the run.
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
}
