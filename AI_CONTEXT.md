# AI Context

This file is the working map for future agents making changes in ProxySmith. Read this before editing the app.

## Product Intent

ProxySmith is a macOS-native deck-to-print workflow for Magic: The Gathering proxies.

The intended flow is:

1. Create a deck.
2. Add cards from Scryfall.
3. Tune print scale.
4. Export A4 sheets as PDF for physical printing.

The app should feel polished and Mac-native, not like a thin CRUD shell.

## Non-Negotiables

- Keep Scryfall traffic conservative.
  API calls currently flow through `ScryfallClient` and `RequestThrottler`.
- Preserve print accuracy.
  `PrintLayout` owns the canonical A4 and MTG card sizing math.
- Keep the app native-first.
  Prefer SwiftUI, SwiftData, and Apple frameworks over extra dependencies.
- Avoid replacing XcodeGen with hand-edited `.pbxproj` changes.
  Update `project.yml`, then regenerate.

## Repo Map

- `project.yml`
  Source of truth for the Xcode project.
- `CHANGELOG.md`
  Must be updated for every commit-worthy change before committing.
- `ProxySmith/App/ProxySmithApp.swift`
  App bootstrap, scene configuration, SwiftData container.
- `ProxySmith/App/ContentView.swift`
  Root navigation and deck selection.
- `ProxySmith/Support/AppPreferences.swift`
  Persistent app-level preferences such as deck-numbering behavior.
- `ProxySmith/Utilities/DeckNameGenerator.swift`
  Canonical logic for untitled deck numbering and sequence handling.
- `ProxySmith/Models/Deck.swift`
  Deck persistence model and deck-level helpers.
- `ProxySmith/Models/DeckCard.swift`
  Stored card data used for deck editing and export.
- `ProxySmith/Models/ScryfallCard.swift`
  API DTOs and image selection logic.
- `ProxySmith/Services/ScryfallClient.swift`
  Rate-limited Scryfall metadata access.
- `ProxySmith/Services/CardImageRepository.swift`
  Cached image fetcher used by export.
- `ProxySmith/Services/PDFExportService.swift`
  PDF generation and cut-guide drawing.
- `ProxySmith/Utilities/PrintLayout.swift`
  Canonical page/card sizing calculations.
- `TestAssets/CardPreviewFixtures`
  Local high-resolution card PNG fixtures used by seeded UI preview testing.

## Current UX Shape

- Sidebar for deck library.
- Main deck workspace with:
  editable name
  scale slider
  add-cards popover
  preview and export actions
  deck list with quantity control and click-to-preview card art that opens at its original framing, supports magnification gestures in the enlarged preview, and can be closed by clicking the same thumbnail again
- Settings window for app-level options such as deck numbering.
- Search sheet for Scryfall-driven card lookup.

## Known Constraints

- Double-faced and special-layout cards currently use the first face image when root `image_uris` are absent.
- Export currently renders the chosen face art with cut guides and a fixed 3x3 grid.
- Export cut guides now sit outside the card frame and align to the exact rectangular trim-edge trajectory of the card frame, which keeps them consistent across the full supported print-scale range.
- Search currently uses Scryfall search syntax directly rather than a curated autocomplete domain model.
- PDF preview now renders from the same in-memory export pipeline as saved files, so preview and export should stay visually aligned.
- UI launches can use `--uitesting-seed-sample-deck` to preload Goblin Sharpshooter and Serra Angel rows backed by local high-resolution PNG fixtures for deterministic preview/debug validation without live network dependence.

## Likely Next Features

- Better card search filtering and sorting
- Deck import from pasted lists
- Duplicate card collapsing and batch quantity editing
- More print presets and paper sizes
- Optional bleed/crop controls

## Workflow Rules For Future Agents

- Use `rg` for searches.
- Use `apply_patch` for manual edits.
- Regenerate the Xcode project after `project.yml` changes.
- Run `xcodebuild -scheme ProxySmith -destination 'platform=macOS' test` before handing off when changes affect app behavior, persistence, or UI flows.
- Update `CHANGELOG.md` before every commit. Treat it as part of the deliverable, not optional documentation.
- Treat any user request to commit as an implicit request to refresh `CHANGELOG.md` and the relevant context files before creating the commit.
- If you change print math or Scryfall behavior, update this file.
