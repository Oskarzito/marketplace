# Marketplace

A small SwiftUI app that shows ads from a remote JSON feed. You can favorite any ad, favorites work offline, and a switch at the top toggles between all ads and only your favorites.

It's built with Xcode 27 and Swift 6 for iOS 27, with no third-party libraries. Open `Marketplace.xcodeproj` and run it on an iOS 27 simulator.

## The solution

The ads load into a lazy grid: two columns on a phone, one when the text size is set very large. Each card shows the photo, title, price and location. Tap a card to open a details screen, or tap the heart to favorite it. Favoriting saves the ad and its image to disk, so the Favorites tab works with no network at all, even when the feed fails to load.

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

I left out a repository layer on purpose. The view model only combines two small protocols, so a repository would just forward calls.

## Decisions

**Images.** `AsyncImage` doesn't let you control its cache and can't show images saved on disk, so I wrote a small `ImageLoader` that keeps decoded images in memory. It decodes them off the main thread (`byPreparingForDisplay`) instead of on first draw while scrolling. Cards use a fixed 4:3 tile so the layout doesn't jump while images load, and a failed image gets a placeholder (two images in the current feed return 404). The image URL from the assignment crops to 4:3 on the server, which cuts off wide logos, so for logos I use the CDN's `480w` variant instead.

**Favorites and offline.** A favorite is a snapshot: the ad plus its image, saved in one JSON file. For a short list that's read once at launch, a file is enough. SwiftData would make sense if I needed to query favorites. I save to disk instead of Caches because the system can clear Caches, which would break offline use. Snapshots are frozen when saved, so an ad that disappears from the feed stays in Favorites with its old price.

**Tapping the heart.** The heart flips right away and the saving happens afterwards. If you tap it again while the image is still downloading, nothing is saved, so you don't end up with a favorite you just removed.

**Concurrency.** The project defaults to main-actor isolation, so anything that shouldn't run on the main actor is marked explicitly:

- `AdsViewModel` is `@MainActor` because it owns the UI state.
- `Ad`, `AdResponse` and `Favorite` are `nonisolated` value types, so they can move between actors.
- `URLSessionAdsService` is `nonisolated`, and the JSON decoding is `@concurrent` so it stays off the main actor.
- `FileFavoritesStore` and `ImageLoader` are actors. The first one serializes file access, the second guards the cache and decodes images.

**Assumptions.** The feed has no currency field, so I show prices as NOK, formatted for Norway.

## What I'm particularly proud of

- I'm happy with how the concurrency turned out: it's explicit under Swift 6 with default main-actor isolation, and the project builds without warnings.

## Improvements

- There are no automated tests. Decoding and the view model are where I'd start.
- The image loader is minimal. It doesn't de-duplicate simultaneous requests, there's no disk cache for images that aren't favorites, and a broken image is requested again every time its card comes back into view.
- The favorites file is rewritten in full on every change and has no versioning. If `Ad` changes in an incompatible way later, saved favorites would be lost.

## With more time

- Pagination.
- A richer details screen.
- Retry saving a favorite's image when the first attempt fails, and refresh saved favorites after each fetch.
- Tests, and an iPad + iPhone Duo layout :)

## AI assistance

This project was built using Claude Code.
