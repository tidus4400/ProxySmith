import AppKit
import PDFKit
import SwiftUI

struct PDFPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppPreferences.self) private var appPreferences
    @Environment(\.colorScheme) private var colorScheme

    let snapshot: DeckExportSnapshot
    let pdfExportService: PDFExportService
    let imageRepository: CardImageRepository

    @State private var previewData: Data?
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                Group {
                    if let previewData {
                        PDFDocumentView(data: previewData)
                            .workshopPanel(.stage, cornerRadius: 22, padding: 12)
                    } else if let errorMessage {
                        ContentUnavailableView(
                            "Preview Unavailable",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text(errorMessage)
                        )
                        .workshopPanel(.panel, cornerRadius: 22, padding: 24)
                    } else {
                        VStack(spacing: 16) {
                            ProgressView()
                                .controlSize(.large)

                            Text("Rendering sheet preview...")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(theme.palette.secondaryText)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .workshopPanel(.panel, cornerRadius: 22, padding: 24)
                    }
                }
                .padding(24)
            }
            .navigationTitle("PDF Preview")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 920, minHeight: 760)
        .task {
            guard isLoading else { return }
            await loadPreview()
        }
    }

    private func loadPreview() async {
        await MainActor.run {
            isLoading = true
            previewData = nil
            errorMessage = nil
        }

        do {
            let renderedData = try await pdfExportService.render(
                snapshot: snapshot,
                imageRepository: imageRepository,
                cacheLifetime: appPreferences.cardImageCacheLifetime
            )
            await MainActor.run {
                previewData = renderedData
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private var theme: AppTheme {
        AppTheme(colorScheme)
    }
}

private struct PDFDocumentView: NSViewRepresentable {
    let data: Data

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.backgroundColor = NSColor.clear
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        pdfView.document = PDFDocument(data: data)
    }
}
