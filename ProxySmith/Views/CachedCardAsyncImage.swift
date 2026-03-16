import AppKit
import SwiftUI

struct CachedCardAsyncImage<Content: View, Placeholder: View>: View {
    @Environment(\.appServices) private var services
    @Environment(AppPreferences.self) private var appPreferences

    let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var image: Image?
    @State private var loadedURL: URL?

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                content(image)
            } else {
                placeholder()
            }
        }
        .task(id: loadID) {
            await loadImage()
        }
    }

    private var loadID: String {
        "\(url?.absoluteString ?? "nil")|\(appPreferences.cardImageCachePeriodDays)"
    }

    private func loadImage() async {
        guard let url else {
            await MainActor.run {
                image = nil
                loadedURL = nil
            }
            return
        }

        await MainActor.run {
            if loadedURL != url {
                image = nil
            }
            loadedURL = url
        }

        do {
            let data = try await services.imageRepository.data(
                for: url,
                maxAge: appPreferences.cardImageCacheLifetime
            )
            guard Task.isCancelled == false,
                  let nsImage = NSImage(data: data) else {
                return
            }

            await MainActor.run {
                guard loadedURL == url else { return }
                image = Image(nsImage: nsImage)
            }
        } catch {
            guard Task.isCancelled == false else { return }

            await MainActor.run {
                guard loadedURL == url else { return }
                image = nil
            }
        }
    }
}
