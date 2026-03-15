import Foundation
import Testing
@testable import ProxySmith

struct LaunchConfigurationTests {
    @Test
    func uiTestSampleDeckIncludesGoblinSharpshooterAndSerraAngel() {
        let deck = LaunchConfiguration.makeUITestSampleDeck()
        let cardsByName = Dictionary(uniqueKeysWithValues: deck.cards.map { ($0.name, $0) })

        #expect(deck.name == "UITest Sample Deck")
        #expect(deck.cards.count == 2)
        #expect(deck.totalCardCount == 3)
        #expect(cardsByName["Goblin Sharpshooter"]?.quantity == 2)
        #expect(cardsByName["Goblin Sharpshooter"]?.setCode == "ONS")
        #expect(cardsByName["Goblin Sharpshooter"]?.previewImageURL?.isFileURL == true)
        #expect(cardsByName["Goblin Sharpshooter"]?.printImageURL?.isFileURL == true)
        #expect(cardsByName["Goblin Sharpshooter"]?.previewImageURL.map { FileManager.default.fileExists(atPath: $0.path) } == true)
        #expect(cardsByName["Serra Angel"]?.quantity == 1)
        #expect(cardsByName["Serra Angel"]?.setCode == "FDN")
        #expect(cardsByName["Serra Angel"]?.previewImageURL?.isFileURL == true)
        #expect(cardsByName["Serra Angel"]?.printImageURL?.isFileURL == true)
        #expect(cardsByName["Serra Angel"]?.previewImageURL.map { FileManager.default.fileExists(atPath: $0.path) } == true)
    }
}
