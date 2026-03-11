import Foundation
import SwiftUI

struct AppServices {
    let scryfallClient: ScryfallClient
    let imageRepository: CardImageRepository
    let pdfExportService: PDFExportService

    static let live = AppServices(
        scryfallClient: ScryfallClient(),
        imageRepository: CardImageRepository(),
        pdfExportService: PDFExportService()
    )
}

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue = AppServices.live
}

extension EnvironmentValues {
    var appServices: AppServices {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }
}

