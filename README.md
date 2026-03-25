# ProxySmith

ProxySmith is a native macOS app for building Magic: The Gathering proxy sheets. It uses SwiftUI for the UI, SwiftData for deck persistence, Scryfall for card metadata/art, and a custom A4 PDF exporter tuned to real card dimensions. The current UI uses a light-first print-studio theme with dark-mode support, solid desktop-style surfaces, and a calmer workspace-focused hierarchy.

## Current Scope

- Create and manage local decks
- Confirm deck deletion before removing a deck and its cards
- Search Scryfall and add cards to a deck
- Adjust quantities per card
- Click deck-list and add-cards search-result images to inspect them at a larger high-resolution size, open them at the default framing, zoom them with pinch or `Command` + scroll, then click the same thumbnail again to close them
- Choose a print scale from 80% to 100%, a per-deck bleed from 0.0 mm to 2.0 mm, and rounded or straight sheet corners
- Configure the app-wide appearance mode, untitled deck numbering, and card-image cache retention in Settings, with immediate `Sync with System` / `Light` / `Dark` application
- Preview print sheets before saving the PDF
- Export print-ready A4 PDFs with 3x3 card layouts, exact edge-matched bleed spacing, optional rounded or straight sheet corners, and cut guides

## Stack

- SwiftUI
- SwiftData
- XcodeGen
- Xcode 26 / Swift 6
- macOS 26 SDK

## Build

```bash
xcodegen generate
xcodebuild -scheme ProxySmith -destination 'platform=macOS' build
xcodebuild -scheme ProxySmith -destination 'platform=macOS' test
```

## Architecture

- `ProxySmith/App`
  App entry point and root split-view composition.
- `ProxySmith/Models`
  SwiftData models plus Scryfall DTOs and export snapshots.
- `ProxySmith/Services`
  Scryfall API client, image repository, and PDF export service.
- `ProxySmith/Views`
  Sidebar, deck workspace, search popover, PDF preview, and deck rows.
- `ProxySmith/Support`
  Shared environment services, theme tokens, and visual styling helpers.
- `ProxySmith/Utilities`
  Print and page layout math.
- `TestAssets/CardPreviewFixtures`
  Local card-image fixtures used for deterministic preview testing.

## Notes

- Scryfall API calls are serialized through a throttler and use a descriptive `User-Agent`.
- Card images are cached on disk under `~/.proxysmith/cache/card-images`, and app preferences are stored at `~/.proxysmith/settings/preferences.json`, including the saved `Sync with System` / `Light` / `Dark` appearance choice.
- Appearance changes apply live to both the main window and the Settings window, including immediate fallback when switching back to `Sync with System`.
- PDF sizing is based on standard MTG dimensions: 2.5" x 3.5" at 72 DPI points, with optional per-deck bleed converted from millimeters into PDF points so neighboring cards separate cleanly and each half-gap inherits the sampled edge color of its neighboring card, falling back to Scryfall border-color metadata when no image sample is available.
