# Overview

## Vision

**SuperMarketStockTakeDesktop** is a read-only desktop companion for **Supermarket Together**. It connects to the local HTTP API served by the **SuperMarketStockTakeAPI** mod (BepInEx plugin) and presents live stock-take and product data so players can inspect shelves, cargo, and session context on a second screen or window without tabbing out of the game.

## Scope

### In scope for v1

- Linux and Windows desktop builds (Flutter).
- Consume **GET-only** JSON from the mod’s default base URL `http://localhost:8080` (see [api-integration.md](api-integration.md)).
- **Connection feedback:** periodic **GET `/ping`** (aligned with the **5s** product poll) with a clear connected (green) / disconnected (red) indicator when the mod is unreachable.
- **Product inventory:** **GET `/products`** every **5 seconds** and on demand. Rows are split by **`containerClassKind`** into two **top** panes (**Storage** left; **Retail shelf** right, including **in storage** beside the quantity column when detected, else at the start of the row) and a **bottom** pane (**Other** kinds and rows without a kind). Each spreadsheet pane: rows **aggregate to one entry per product** (same key as `productId` / `id` / … correlation), then sort **low to high by quantity** (ascending `sortTotalForRow`); **`storage` / `retailShelf` count columns merge** when both exist on a row; **product id** columns appear first in the grid; **`slotIndex`** is hidden. Low shelf (under **10**): **orange** pulse when the same product still has stock in **storage**, otherwise **red**; **storage** and **Other** panes use **red** only (see [api-integration.md](api-integration.md)). A compact **last-fetch** line shows time, totals, and per-bucket row counts.
- Clear error and warning states (HTTP failures, optional JSON `error` field when game state is not ready).
- Further views: session **GET `/stats`**, **GET `/spawnedProducts`**, subject to [roadmap.md](roadmap.md).

### Nice-to-haves

- **Optimal in-game retail (“best shelf price”)** surfaced in the UI **only when** the mod/API provides authoritative or reference fields (cost, market price, suggestions); until then the app stays **stock-first**—see [pricing-research.md](pricing-research.md) and [roadmap.md](roadmap.md).
- Configurable API base URL in the app (when the mod or deployment allows a non-default host/port).
- Filtering, search, and simple export (e.g. CSV) for product tables.
- Strongly typed Dart models for `/products` (today: dynamic maps + parsing helpers in `product_rows.dart`).
- Packaging and update story appropriate for a small sidecar tool.

### Non-goals

- **Writing back into the game** (inventory edits, spawning, cheats) unless the companion API explicitly gains safe, documented write endpoints and the project chooses to support them.
- Replacing the in-game UI or acting as a full game launcher.
- Mobile or web targets (unless deliberately expanded later).

## Constraints

- **API contract** is owned by **SuperMarketStockTakeAPI**; this app must tolerate `error` payloads and empty or partial data when game state is not ready.
- **Offline / no server**: the app should fail gracefully (message, retry) when localhost is unreachable; the connection indicator reflects reachability of **GET `/ping`**.
- **Platforms**: primary targets are **Linux** and **Windows** desktop per repository layout; `flutter doctor` should show the relevant desktop enablement before release builds.
- **Data shape**: JSON is camelCase per API notes; `/products` is parsed flexibly until fixed Dart types exist — keep [api-integration.md](api-integration.md) aligned with the mod and with any new models.
