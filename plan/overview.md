# Overview

## Vision

**SuperMarketStockTakeDesktop** is a read-only desktop companion for **Supermarket Together**. It connects to the local HTTP API served by the **SuperMarketStockTakeAPI** mod (BepInEx plugin) and presents live stock-take and product data so players can inspect shelves, cargo, and session context on a second screen or window without tabbing out of the game.

## Scope

### In scope for v1

- Linux and Windows desktop builds (Flutter).
- Consume **GET-only** JSON from the mod’s default base URL `http://localhost:8080` (see [api-integration.md](api-integration.md)).
- Clear connection and error states when the game or API is unavailable.
- Views that help stock take: at minimum progression from liveness (`/ping`) through session stats (`/stats`), product/shelf data (`/products`), and spawned/cargo-related data (`/spawnedProducts`), subject to roadmap ordering.

### Nice-to-haves

- Configurable API base URL in the app (when the mod or deployment allows a non-default host/port).
- Filtering, search, and simple export (e.g. CSV) for product tables.
- Packaging and update story appropriate for a small sidecar tool.

### Non-goals

- **Writing back into the game** (inventory edits, spawning, cheats) unless the companion API explicitly gains safe, documented write endpoints and the project chooses to support them.
- Replacing the in-game UI or acting as a full game launcher.
- Mobile or web targets (unless deliberately expanded later).

## Constraints

- **API contract** is owned by **SuperMarketStockTakeAPI**; this app must tolerate `error` payloads and empty or partial data when game state is not ready.
- **Offline / no server**: the app should fail gracefully (message, retry) when localhost is unreachable.
- **Platforms**: primary targets are **Linux** and **Windows** desktop per repository layout; `flutter doctor` should show the relevant desktop enablement before release builds.
- **Data shape**: JSON is camelCase per API notes; typed Dart models and this folder’s API doc should stay aligned as features land.
