# Marketplace

A small SwiftUI app that shows ads from a remote JSON feed. Any ad can be favorited, favorites are available offline, and a switch toggles between all ads and favorites.

- Xcode 27, iOS 27, Swift 6 language mode. No third-party dependencies.
- Open `Marketplace.xcodeproj` and run on an iOS 27 simulator.

## The solution

Ads load into a lazy, adaptive grid (two columns on a phone, one at accessibility text sizes). Each card shows photo, title, price and location, and tapping a card opens a details screen. Tapping the heart saves the ad **and its image bytes** to disk, so the Favorites tab can be shown with no network at all. The feed's failure never affects Favorites.

```
Models/       Ad               what the app shows and saves
              AdResponse       mirrors the JSON field for field, maps to Ad
              Favorite         an Ad plus its image bytes
Services/     AdsService       protocol + URLSession implementation
              FavoritesStore   protocol + JSON-file actor
              ImageLoader      actor: memory cache, off-main decoding
ViewModels/   AdsViewModel     combines the service and the store
Views/        AdsListView, AdCardView, AdDetailView, AdImageView, FavoriteButton
```

There is deliberately no repository layer: the view model combines two small protocols, and a repository would only forward calls.

## Decisions

**Images.** `AsyncImage` has no cache you control and cannot show saved bytes, so a small `ImageLoader` actor keeps decoded images in memory and decodes them off the main thread (`byPreparingForDisplay`), rather than on first draw while scrolling. Cards use a fixed 4:3 tile so layout does not jump while images load, and a failed image shows a placeholder (two images in the current feed return 404). The brief's image URL crops to 4:3 on the server, which clips wide logos, so logo-typed images use the CDN's `480w` variant. That variant is not in the brief; I found it by testing.

**Favorites and offline.** A favorite is a snapshot: the `Ad` plus the image bytes, stored as one JSON file. A file is enough for a short list read at launch; SwiftData would make sense if favorites needed queries. Disk is used, not Caches, because the system may purge Caches and that would break offline use. Snapshots are frozen when saved, so an ad that disappears from the feed stays in Favorites with its old price.

**Tapping the heart.** The heart flips immediately; saving happens afterwards. If the user taps again while the image is still downloading, nothing is saved, so no ghost favorite is left behind.

**Concurrency.** The project uses default `MainActor` isolation, so everything that should not run on the main actor is marked explicitly.

| Type | Isolation | Why |
|---|---|---|
| `AdsViewModel` | `@MainActor` | owns UI state |
| `Ad`, `AdResponse`, `Favorite` | `nonisolated`, `Sendable` value types | cross actor boundaries |
| `URLSessionAdsService` | `nonisolated`; decoding is `@concurrent` | keeps JSON decoding off the main actor |
| `FileFavoritesStore` | `actor` | serializes file access without locks |
| `ImageLoader` | `actor` | guards the cache; decodes off the main thread |

**Assumptions.** The feed has no currency field, so prices are shown as NOK, formatted for Norway.

## What I am particularly proud of

- Concurrency is explicit under Swift 6 with default main-actor isolation, and the project builds without warnings.

## Improvements

- There are no automated tests. The decoding and the view model are the first things I would cover.
- The image loader is slim: no de-duplication of simultaneous requests, no disk cache for non-favorites, and a broken image is requested again every time its card reappears.
- The favorites file is rewritten as a whole on each change and has no versioning, so a future incompatible change to `Ad` would lose saved favorites.

## With more time

- Pagination.
- A richer details screen. 
- Retrying to save a favorite's image, and refreshing saved snapshots after each fetch.
- Tests, an iPad + iPhone Duo layout :)

## AI assistance

This project was built using Claude Code. 
