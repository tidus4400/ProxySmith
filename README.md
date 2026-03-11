# ProxySmith

ProxySmith is a native macOS app for building Magic: The Gathering proxy sheets. It uses SwiftUI for the UI, SwiftData for deck persistence, Scryfall for card metadata/art, and a custom A4 PDF exporter tuned to real card dimensions.

## Current Scope

- Create and manage local decks
- Search Scryfall and add cards to a deck
- Adjust quantities per card
- Choose a print scale from 80% to 100%
- Export print-ready A4 PDFs with 3x3 card layouts and cut guides

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
```

## Architecture

- `ProxySmith/App`
  App entry point and root split-view composition.
- `ProxySmith/Models`
  SwiftData models plus Scryfall DTOs and export snapshots.
- `ProxySmith/Services`
  Scryfall API client, image repository, and PDF export service.
- `ProxySmith/Views`
  Sidebar, deck workspace, search flow, and deck rows.
- `ProxySmith/Support`
  Shared environment services and visual styling helpers.
- `ProxySmith/Utilities`
  Print and page layout math.

## Notes

- Scryfall API calls are serialized through a throttler and use a descriptive `User-Agent`.
- PDF sizing is based on standard MTG dimensions: 2.5" x 3.5" at 72 DPI points.
