import Foundation
import SwiftUI

struct AppServices {
    let scryfallClient: ScryfallClient
    let imageRepository: CardImageRepository
    let pdfExportService: PDFExportService

    static func live(
        storageLayout: ProxySmithStorageLayout,
        preferredCardImageCacheDirectory: URL? = nil
    ) -> AppServices {
        AppServices(
            scryfallClient: ScryfallClient(),
            imageRepository: CardImageRepository(
                storage: LaunchConfiguration.makeImageCacheStorage(
                    storageLayout: storageLayout,
                    preferredCardImageCacheDirectory: preferredCardImageCacheDirectory
                )
            ),
            pdfExportService: PDFExportService()
        )
    }
}

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue = AppServices.live(storageLayout: LaunchConfiguration.makeStorageLayout())
}

extension EnvironmentValues {
    var appServices: AppServices {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }
}
