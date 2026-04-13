# API integration

Companion API: **SuperMarketStockTakeAPI** (BepInEx plugin, localhost HTTP).

## Base URL

Default: `http://localhost:8080` (configurable later if the mod supports it).

## Client behavior (Dart)

The app uses [`StockTakeApiClient`](../src/lib/api/stock_take_api_client.dart):

- **Method:** HTTP GET only.
- **Success:** status 2xx; body decoded with `getJson` (any JSON value) or `getJsonMap` (object only; array root throws `FormatException`).
- **Failure:** non-2xx → `StockTakeApiException` with status and body text.

## Endpoints (GET)

| Path | Use in app |
|------|------------|
| `/ping` | **Connection health:** `getJsonMap('/ping')` on the same **5s** timer as `/products` (plus first tick after startup); drives app bar green/red/grey indicator ([`main.dart`](../src/lib/main.dart)). |
| `/stats` | Not used in UI yet; planned session snapshot (`time`, `frame`, `level`). |
| `/products` | **Primary data view:** `getJson('/products')` every **5s** (background) + manual refresh. Rows split by **`containerClassKind`** ([`products_pane_layout.dart`](../src/lib/widgets/products_pane_layout.dart)): **Storage** (left); **Retail shelf** (top right), spreadsheet with **in storage** after the first recognized quantity-style column when present (aggregated storage totals per [`productStockCorrelationKey`](../src/lib/products/product_rows.dart)); **Other** full width below the top row. Spreadsheets: sort, storage/retail merge, low-stock flash — **retail** uses **orange** when the same product still has quantity in **storage**, otherwise **red**; **storage** and **Other** use **red** only. Last-fetch line includes per-bucket counts. See [`main.dart`](../src/lib/main.dart), [`product_rows.dart`](../src/lib/products/product_rows.dart), [`products_spreadsheet.dart`](../src/lib/widgets/products_spreadsheet.dart). |
| `/spawnedProducts` | Not used in UI yet; cargo queue, shopping list, delivery boxes. |

## Errors and readiness

- Responses may include an **`error`** field when game state is not ready. UI should surface it clearly and avoid treating the payload as full success data.
- Align handling with typed models once they exist (e.g. nullable top-level fields vs. error-only object).

## Response contracts (keep in sync with Dart models)

When you add or change a Dart model under `src/lib/`, update the matching subsection here so the mod, the types, and this doc agree.

### GET `/ping`

| Field | Type | Notes |
|-------|------|-------|
| _TBD_ | _TBD_ | No dedicated Dart model; success = any 2xx JSON **object** (body parsed, not shown in UI). Failure or non-object → connection indicator **red**. Add field rows when a typed response is introduced. |

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
| (flexible) | object or array | Root may be a **JSON array** of product objects, or an **object** whose array lives under e.g. `products`, `items`, `data`, or the longest list-valued property. See [`product_rows.dart`](../src/lib/products/product_rows.dart). |
| `containerClassKind` | string? | **Layout:** normalized (case-insensitive, spaces/underscores stripped) to **storage** → left pane; **retailshelf** or **retainshelf** or any string containing both **retail** and **shelf** → right pane; **anything else** (including missing) → bottom **Other** pane. Also accepts **`ContainerClassKind`** as a key alias. In the left and right panes the kind column is **hidden** as redundant; **Other** keeps it when present. Logic: [`containerClassBucketForRow`](../src/lib/products/product_rows.dart). |
| (correlation) | — | Same key as row **aggregation/grouping** and storage↔retail **orange** flash: **`productId`**, then **`id`**, then **`sku`**, then **`productName` / `name` / `displayName`** ([`productStockCorrelationKey`](../src/lib/products/product_rows.dart)). Multiple rows for the same product collapse into **one entry** per pane via [`aggregateRowsByProductKey`](../src/lib/products/product_rows.dart); quantity-like fields are summed (e.g. `5 + 24 = 29`). Storage quantity summed per key via [`storageStockTotalsByProductKey`](../src/lib/products/product_rows.dart). |
| `error` | string? | Optional; surfaced in the UI when present. |

**Desktop app behavior:** decodes any JSON value via `getJson('/products')`, **splits** rows with [`splitRowsByContainerClassKind`](../src/lib/products/product_rows.dart), then for each bucket runs [`prepareProductPane`](../src/lib/products/product_rows.dart) (**aggregate to one row per product**, then sort **low → high by quantity** using [`sortRowsByLowestTotalCount`](../src/lib/products/product_rows.dart) / [`sortTotalForRow`](../src/lib/products/product_rows.dart); **`productId` / `id` / `sku`** columns listed first in the table header order). `slotIndex` is intentionally omitted from the grid. If rows include **`storage`** and/or **`retailShelf`**, those two fields are **merged** into one column `storage · retailShelf` (values shown as `left · right`, with `—` for missing). Sorting and the low-stock flash use the **numeric sum** of `storage` + `retailShelf` when those keys exist (or the internal total after merge). Otherwise, sort uses the first matching count-like field among `totalCount`, `total`, `count`, `quantity`, `stock`, `amount`, `shelfCount`, `owned`, `inventoryCount`, `qty`, or the sum of numeric values in the row. Rows where `sortTotalForRow(row)` is **strictly below `kLowStockFlashThreshold` (10)** pulse: **retail shelf** pane → **orange** if [`retailShelfUsesOrangeLowStockFlash`](../src/lib/products/product_rows.dart) (matching storage row total **greater than 0**), else **red**; **storage** and **Other** panes → **red** only. Internal keys starting with `_` are omitted from columns.

**Polling:** timer interval **5 seconds**; background failures update the **last-fetch** line only (table left as last good data). Manual refresh clears the main error banner path and shows the linear progress indicator when loading.

#### Retail pricing (planned; out of scope until mod confirms)

Suggested or “best” **shelf** pricing for **Supermarket Together** is **not implemented** in the desktop app until **SuperMarketStockTakeAPI** documents and returns usable fields. Game context (Pricing Device, markups, inflation) is summarized in [pricing-research.md](pricing-research.md). Roadmap todos track documentation and optional UI.

| Field (examples) | Type | Notes |
|------------------|------|-------|
| `marketPrice` | _TBD_ | Reference / market-style price from the game, if the mod exposes it. |
| `cost` | _TBD_ | Purchase or wholesale cost per unit, if exposed. |
| `shelfPrice` | _TBD_ | Current player-set shelf price, if exposed. |
| `suggestedPrice` | _TBD_ | Optional mod-computed hint. |

Replace `_TBD_` rows with real names, types, and semantics once sample JSON exists; then extend Dart models and the spreadsheet.

### GET `/spawnedProducts`

| Field | Type | Notes |
|-------|------|-------|
| _TBD_ | _TBD_ | Document when spawned/cargo models and UI exist. |

## Notes

- Prefer capturing one real JSON sample (redacted if needed) when locking down a schema, then mirror field names and nullability in Dart and in the tables above.
