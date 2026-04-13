# API integration

Companion API: **SuperMarketStockTakeAPI** (BepInEx plugin, localhost HTTP).

## Base URL

Default: `http://localhost:8080` (configurable later if the mod supports it).

## Client behavior (Dart)

The app uses [`StockTakeApiClient`](../src/lib/api/stock_take_api_client.dart):

- **Method:** HTTP GET only.
- **Success:** status 2xx; body decoded as a single JSON **object** (`Map<String, dynamic>`). Arrays at the root are rejected by `getJsonMap` (FormatException).
- **Failure:** non-2xx → `StockTakeApiException` with status and body text.

## Endpoints (GET)

| Path | Use in app |
|------|------------|
| `/ping` | Liveness / version. |
| `/stats` | Session snapshot (`time`, `frame`, `level`). |
| `/products` | Shelf stock + catalog (camelCase JSON). |
| `/spawnedProducts` | Cargo queue, shopping list, delivery boxes. |

## Errors and readiness

- Responses may include an **`error`** field when game state is not ready. UI should surface it clearly and avoid treating the payload as full success data.
- Align handling with typed models once they exist (e.g. nullable top-level fields vs. error-only object).

## Response contracts (keep in sync with Dart models)

When you add or change a Dart model under `src/lib/`, update the matching subsection here so the mod, the types, and this doc agree.

### GET `/ping`

| Field | Type | Notes |
|-------|------|-------|
| _TBD_ | _TBD_ | No dedicated Dart model yet; [`main.dart`](../src/lib/main.dart) displays the raw map. Add rows when a type is introduced (confirm against live JSON or the mod source). |

### GET `/stats`

| Field | Type | Notes |
|-------|------|-------|
| `time` | _TBD_ | Planned session snapshot field (see mod). |
| `frame` | _TBD_ | Planned session snapshot field (see mod). |
| `level` | _TBD_ | Planned session snapshot field (see mod). |

_Additional fields: document when `/stats` UI and models are implemented._

### GET `/products`

| Field | Type | Notes |
|-------|------|-------|
| _TBD_ | _TBD_ | Document when product/shelf models and UI exist (camelCase JSON per mod). |

### GET `/spawnedProducts`

| Field | Type | Notes |
|-------|------|-------|
| _TBD_ | _TBD_ | Document when spawned/cargo models and UI exist. |

## Notes

- Prefer capturing one real JSON sample (redacted if needed) when locking down a schema, then mirror field names and nullability in Dart and in the tables above.
