import Foundation

struct ScryfallSearchResponse: Decodable {
    let data: [ScryfallCard]
}

struct ScryfallCard: Decodable, Identifiable, Hashable {
    struct ImageURIs: Decodable, Hashable {
        let png: URL?
        let large: URL?
        let normal: URL?
        let small: URL?
    }

    struct CardFace: Decodable, Hashable {
        let name: String?
        let manaCost: String?
        let typeLine: String?
        let imageUris: ImageURIs?
    }

    let id: String
    let name: String
    let set: String
    let setName: String
    let collectorNumber: String
    let manaCost: String?
    let typeLine: String?
    let rarity: String
    let imageUris: ImageURIs?
    let cardFaces: [CardFace]?

    var previewImageURL: URL? {
        preferredImage(
            primary: imageUris,
            fallback: cardFaces?.first?.imageUris,
            candidates: [\.small, \.normal]
        )
    }

    var printImageURL: URL? {
        preferredImage(
            primary: imageUris,
            fallback: cardFaces?.first?.imageUris,
            candidates: [\.png, \.large, \.normal]
        )
    }

    var displayName: String {
        cardFaces?.first?.name ?? name
    }

    var displayManaCost: String {
        cardFaces?.first?.manaCost ?? manaCost ?? ""
    }

    var displayTypeLine: String {
        cardFaces?.first?.typeLine ?? typeLine ?? ""
    }

    private func preferredImage(
        primary: ImageURIs?,
        fallback: ImageURIs?,
        candidates: [KeyPath<ImageURIs, URL?>]
    ) -> URL? {
        for candidate in candidates {
            if let url = primary?[keyPath: candidate] {
                return url
            }
        }

        for candidate in candidates {
            if let url = fallback?[keyPath: candidate] {
                return url
            }
        }

        return nil
    }
}

struct ScryfallAPIError: Decodable, Error, LocalizedError {
    let object: String
    let code: String?
    let status: Int?
    let details: String
    let type: String?
    let warnings: [String]?

    var errorDescription: String? {
        details
    }
}
