import Foundation

struct ProxySmithStorageLayout: Sendable {
    let rootDirectory: URL

    var settingsDirectory: URL {
        rootDirectory.appendingPathComponent("settings", isDirectory: true)
    }

    var settingsFile: URL {
        settingsDirectory.appendingPathComponent("preferences.json", isDirectory: false)
    }

    var cacheDirectory: URL {
        rootDirectory.appendingPathComponent("cache", isDirectory: true)
    }

    var cardImageCacheDirectory: URL {
        cacheDirectory.appendingPathComponent("card-images", isDirectory: true)
    }
}

extension URL {
    func pathRelativeToHome(fileManager: FileManager = .default) -> String {
        let homePath = fileManager.homeDirectoryForCurrentUser.path
        guard path.hasPrefix(homePath) else {
            return path
        }

        return path.replacingOccurrences(of: homePath, with: "~", options: [.anchored])
    }
}
