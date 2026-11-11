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

**Response type vs. domain model.** `AdResponse` is shaped by the backend; `Ad` is shaped by the UI and by what is saved as a favorite. A backend change touches one type and one mapping, and saved favorites keep decoding. `AdResponse` mirrors every field, including ones the UI does not use. `ad-type` is not modelled in `Ad` because the UI does not vary by it.

**Images.** `AsyncImage` has no cache you control and cannot show saved bytes, so a small `ImageLoader` actor keeps decoded images in memory and decodes them off the main thread (`byPreparingForDisplay`), rather than on first draw while scrolling. Cards use a fixed 4:3 tile so layout does not jump while images load, and a failed image shows a placeholder (two images in the current feed return 404). The brief's image URL crops to 4:3 on the server, which clips wide logos, so logo-typed images use the CDN's `480w` variant. That variant is not in the brief; I found it by testing.

**Favorites and offline.** A favorite is a snapshot: the `Ad` plus the image bytes, stored as one JSON file in Application Support. A file is enough for a short list read at launch; SwiftData would make sense if favorites needed queries. Application Support, not Caches, because the system may purge Caches and that would silently break offline use. Writes are atomic. Snapshots are frozen when saved, so an ad that disappears from the feed stays in Favorites with its old price.

**Tapping the heart.** The heart flips immediately; saving happens afterwards. If the user taps again while the image is still downloading, nothing is saved, so no ghost favorite is left behind.

**Concurrency.** The project uses default `MainActor` isolation, so everything that should not run on the main actor is marked explicitly.

| Type | Isolation | Why |
|---|---|---|
| `AdsViewModel` | `@MainActor` | owns UI state |
| `Ad`, `AdResponse`, `Favorite` | `nonisolated`, `Sendable` value types | cross actor boundaries |
| `URLSessionAdsService` | `nonisolated`; decoding is `@concurrent` | keeps JSON decoding off the main actor |
| `FileFavoritesStore` | `actor` | serializes file access without locks |
| `ImageLoader` | `actor` | guards the cache; decodes off the main thread |

Loads started by `.task` are cancelled with the view, and cancellation is not shown as an error.

**Assumptions.** The feed has no currency field, so prices are shown as NOK, formatted for Norway. The feed holds 20 ads although `size` says 200, and the brief gives no paging contract, so there is no pagination. Ads without a price (job ads) show no price line.

## What I am particularly proud of

- Favorites really work offline: the saved record is self-contained (data and image), and the tab does not depend on the feed.
- The code is small (about 700 lines) and each type has one job, with protocol seams at the two places that do I/O.
- Concurrency isolation is explicit and explained instead of relying on the build setting.

## What could have been done better

- There are no automated tests. The decoding and the view model are the first things I would cover.
- I have not profiled scrolling in Instruments, and I have not tested with VoiceOver on a device.
- The image loader is slim: no de-duplication of simultaneous requests, no disk cache for non-favorites, and a broken image is requested again every time its card reappears.
- A favorite saved while offline has no image. A failed pull-to-refresh and a failed favorite save are silent.
- The favorites file is rewritten as a whole on each change and has no versioning, so a future incompatible change to `Ad` would lose saved favorites.
- Job cards leave a small gap between title and location, because every title reserves two lines.

## With more time

- Pagination, once the API supports it.
- A richer details screen. It shows the same data as the card, larger. The feed also has type-specific fields (company, employment type and published age for jobs, total price for real estate, shipping option) that it could show, and a sharper image: the CDN also serves 960x720 photos.
- De-duplicating in-flight image requests, a disk cache, and remembering failed URLs.
- Retrying to save a favorite's image, and refreshing saved snapshots after each fetch.
- Unit tests, UI tests, localized strings, an iPad layout, and haptics on the heart.
