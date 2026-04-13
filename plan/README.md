# Project plan

Markdown notes for goals, milestones, and technical decisions for **SuperMarketStockTakeDesktop**.

## Keeping this folder current

Whenever behavior or API usage changes in `src/`, update the relevant file here in the same change (or immediately after):

| After you change… | Update… |
|-------------------|---------|
| Endpoints, JSON shapes, client methods | [api-integration.md](api-integration.md) |
| Shipped features or milestone order | [roadmap.md](roadmap.md) |
| Product vision, scope, or constraints | [overview.md](overview.md) |
| In-game pricing research or mod pricing fields | [pricing-research.md](pricing-research.md) + [api-integration.md](api-integration.md) + [roadmap.md](roadmap.md) |

## Files

| File | Intent |
|------|--------|
| [`overview.md`](overview.md) | Vision, scope, non-goals. |
| [`roadmap.md`](roadmap.md) | Phases and ordered deliverables (checked = matches `src/lib` today). |
| [`api-integration.md`](api-integration.md) | How the app maps to SuperMarketStockTakeAPI endpoints and payloads. |
| [`pricing-research.md`](pricing-research.md) | **Supermarket Together** in-game vs Steam pricing notes; links for follow-up. |

## Key implementation references (Flutter)

| Area | Location |
|------|----------|
| API client (`getJson`, `getJsonMap`) | [`src/lib/api/stock_take_api_client.dart`](../src/lib/api/stock_take_api_client.dart) |
| Home UI, connection check, product load | [`src/lib/main.dart`](../src/lib/main.dart) |
| `/products` parse, split, per-product aggregation, low→high quantity sort, `kLowStockFlashThreshold`, storage merge, correlation | [`src/lib/products/product_rows.dart`](../src/lib/products/product_rows.dart) |
| Three-pane layout (storage / retail shelf / other) | [`src/lib/widgets/products_pane_layout.dart`](../src/lib/widgets/products_pane_layout.dart) |
| Spreadsheet table widget | [`src/lib/widgets/products_spreadsheet.dart`](../src/lib/widgets/products_spreadsheet.dart) |
