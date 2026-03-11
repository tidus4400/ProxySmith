import Foundation
import Observation

@MainActor
@Observable
final class AppPreferences {
    private enum Keys {
        static let globalDeckNumberingEnabled = "globalDeckNumberingEnabled"
        static let nextGlobalDeckNumber = "nextGlobalDeckNumber"
    }

    private let defaults: UserDefaults

    var globalDeckNumberingEnabled: Bool {
        didSet {
            defaults.set(globalDeckNumberingEnabled, forKey: Keys.globalDeckNumberingEnabled)
        }
    }

    var nextGlobalDeckNumber: Int {
        didSet {
            if nextGlobalDeckNumber < 1 {
                nextGlobalDeckNumber = 1
                return
            }

            defaults.set(nextGlobalDeckNumber, forKey: Keys.nextGlobalDeckNumber)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.globalDeckNumberingEnabled: true,
            Keys.nextGlobalDeckNumber: 1
        ])

        globalDeckNumberingEnabled = defaults.bool(forKey: Keys.globalDeckNumberingEnabled)
        nextGlobalDeckNumber = max(defaults.integer(forKey: Keys.nextGlobalDeckNumber), 1)
    }

    func resetDeckNumberCounter() {
        nextGlobalDeckNumber = 1
    }
}

