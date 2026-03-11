import Foundation
import SwiftData

enum LaunchConfiguration {
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
    static let shouldResetState = ProcessInfo.processInfo.arguments.contains("--uitesting-reset-state")

    private static let uiTestingDefaultsSuiteName = "com.tidus4400.ProxySmith.UITests"

    static func makeUserDefaults() -> UserDefaults {
        guard isUITesting else {
            return .standard
        }

        let defaults = UserDefaults(suiteName: uiTestingDefaultsSuiteName) ?? .standard

        if shouldResetState {
            defaults.removePersistentDomain(forName: uiTestingDefaultsSuiteName)
        }

        return defaults
    }

    static func makeModelConfiguration() -> ModelConfiguration {
        ModelConfiguration(isStoredInMemoryOnly: isUITesting)
    }
}

