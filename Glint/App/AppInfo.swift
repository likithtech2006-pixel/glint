import Foundation

enum AppInfo {
    /// The app's name everywhere in the UI. Set by APP_NAME in Config/Glint.xcconfig.
    static let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Glint"

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
