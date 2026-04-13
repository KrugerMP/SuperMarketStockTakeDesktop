# Roadmap

Phases are ordered deliverables. Checked items match what the Flutter app does today in `src/lib/`.

## Phase 1 — Foundation

- [x] Flutter desktop scaffold (Linux/Windows) under `src/`.
- [x] Shared GET JSON client with default base `http://localhost:8080` ([`stock_take_api_client.dart`](../src/lib/api/stock_take_api_client.dart)).
- [x] Home screen: show API base URL, call **GET `/ping`**, display JSON or HTTP/format errors, manual refresh.

## Phase 2 — Live session and inventory UX

- [ ] **GET `/stats`**: session snapshot UI (`time`, `frame`, `level` per API notes).
- [ ] **GET `/products`**: table or list for shelf stock + catalog; handle `error` when state not ready.
- [ ] **GET `/spawnedProducts`**: cargo queue, shopping list, delivery boxes (layout TBD).
- [ ] Typed Dart models for the above responses; keep [api-integration.md](api-integration.md) in sync.

## Phase 3 — Polish and operations

- [ ] User-configurable API base URL (and persistence) if still needed once the mod’s configuration story is clear.
- [ ] Consistent empty, loading, and error states across all panels.
- [ ] Optional: filters, search, export for product views.
- [ ] Release builds and packaging notes (versioning, artifacts per platform).
