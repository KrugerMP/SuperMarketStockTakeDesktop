# Supermarket Together: pricing research

Companion context: **SuperMarketStockTakeDesktop** reads live product rows from **SuperMarketStockTakeAPI**; it does not yet model retail economics. This note separates **buying the game** from **in-game shelf pricing** and records community-sourced mechanics so roadmap work can stay honest about what is authoritative vs heuristic.

## Steam store (not shelf economics)

**Supermarket Together** is **free to play** on Steam (AppID 2709570). Optional paid DLC exists (e.g. “The Cool Pack”); third-party key prices vary. That is unrelated to per-product **shelf** prices inside a play session.

## In-game retail: mechanics and “best” price

There is **no single canonical best shelf price per SKU** in public first-party docs surfaced here; optimal retail is **situational** (cost, demand, player tolerance).

Community guides and articles (Steam Community guides, GameSkinny, similar walkthroughs) describe:

- **Pricing Device** (manager area): aim at shelves to compare **market / reference** style pricing to **your shelf price**; adjust with mouse wheel (small steps) or **E + scroll** for larger steps; some guides mention **numpad** entry after focusing a price.
- **Markup heuristics**: many players report **modest markups** (often cited around **5–10%** above reference / what you paid) as a balance between profit and customers walking away; **very high** prices reduce sales. Some community **calculator** guides propose formula-style targets—treat those as **player meta**, not official game rules.
- **Dynamic economy**: guides often describe **periodic inflation** on some products (frequently tied to a **weekly** cadence, e.g. **Thursday** in player write-ups). Any “best” shelf price should be **revisited** when the game shifts underlying costs or demand.

### Further reading (community; verify in-game after patches)

- Steam Community: [Supermarket Together Price Calculator](https://steamcommunity.com/sharedfiles/filedetails/?id=3432543343) (workshop guide; content may change).
- Steam Community: [The ultimate Supermarket Together Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3332799668) (workshop guide; content may change).

When the mod exposes **cost**, **market**, or **suggested** fields on `/products` (or another route), document them in [api-integration.md](api-integration.md) and consider UI columns or a “suggested shelf” hint—see [roadmap.md](roadmap.md).
