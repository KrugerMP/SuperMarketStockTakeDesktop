# Roadmap

Phases are ordered deliverables. Checked items match what the Flutter app does today in `src/lib/`.

## Phase 1 — Foundation

- [x] Flutter desktop scaffold (Linux/Windows) under `src/`.
- [x] Shared GET JSON client with default base `http://localhost:8080` ([`stock_take_api_client.dart`](../src/lib/api/stock_take_api_client.dart)), including `getJson` (any root) and `getJsonMap` (object only).
- [x] **GET `/ping`** used for **reachability**: shared **5s** poll with `/products` + app bar indicator (green = connected, red = disconnected, grey = not yet checked).
- [x] Home screen shows API base URL, **GET `/products`** on load and **every 5s**, compact **last-fetch** status line, manual **refresh** for products, loading strip on manual refresh, error banner on manual failure (silent poll failures update last-fetch only).

## Phase 2 — Live session and inventory UX

- [x] **GET `/products`**: split UI by **`containerClassKind`** — **Storage** | **Retail shelf** (top), **Other** (bottom) ([`products_pane_layout.dart`](../src/lib/widgets/products_pane_layout.dart)); per-pane spreadsheets ([`products_spreadsheet.dart`](../src/lib/widgets/products_spreadsheet.dart)), flexible parsing ([`product_rows.dart`](../src/lib/products/product_rows.dart)), **one row per product** (quantity-like fields summed), **low→high quantity** ordering, storage/retail merge, id columns first, `slotIndex` hidden; **retail** shows **in storage** next to the quantity column when detected; low-stock pulse below **`kLowStockFlashThreshold` (10)** — **retail**: **orange** when matched storage still has stock, else **red**; **storage**/**Other**: **red**; optional top-level `error` in UI.
- [ ] **GET `/stats`**: session snapshot UI (`time`, `frame`, `level` per API notes).
- [ ] **GET `/spawnedProducts`**: cargo queue, shopping list, delivery boxes (layout TBD).
- [ ] Typed Dart models for `/stats`, `/spawnedProducts`, and optionally tighten `/products`; keep [api-integration.md](api-integration.md) in sync.
- [ ] **In-game pricing research / doc**: Keep [pricing-research.md](pricing-research.md) aligned with **Supermarket Together** (Pricing Device, markup heuristics, inflation cadence); prefer paraphrase + links, not scraped guide text.
- [ ] **Suggested shelf pricing in UI** (optional): When **SuperMarketStockTakeAPI** exposes cost / market / suggested / current shelf fields on `/products` (or elsewhere), add columns or hints and sync [api-integration.md](api-integration.md). Until then, retail “best price” stays out of the app—see **Retail pricing (planned)** in that file.

## Phase 3 — Polish and operations

- [ ] User-configurable API base URL (and persistence) if still needed once the mod’s configuration story is clear.
- [ ] Consistent empty, loading, and error states across **all** panels (products partially covered).
- [ ] Optional: filters, search, export for product views.
- [ ] Release builds and packaging notes (versioning, artifacts per platform).
