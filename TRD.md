# TRD — Technical Requirements Document

## 1. Platform & Constraints
- Flutter **stable channel**. Must run with `flutter pub get && flutter run` — zero extra setup (no code generation step left un-run, no manual env files, no external services).
- Target: Android + iOS simulators/devices at minimum (evaluator likely runs on one or both).
- No backend. All "market data" is generated in-process.

## 2. Tech Stack (proposed)
| Concern | Choice | Why |
|---|---|---|
| State management | **Riverpod** (`flutter_riverpod`) | Fine-grained rebuilds via `Provider.select`/`Consumer` scoping — critical for F2's "only affected cells rebuild" requirement. Testable, no BuildContext coupling for the feed. |
| Local persistence | **Drift (SQLite)** for watchlists/orders/holdings; simple key-value (e.g. `shared_preferences`) for wallet balance & settings | Relational data (watchlists ↔ stocks, order history) fits SQL; transactional writes protect holdings integrity. |
| Money type | Custom `Money` value type backed by `int` (minor units, paise) or `Decimal` package | Eliminates float drift in price × qty math. |
| Feed/streams | `Stream`/`StreamController` (broadcast) per symbol, or one multiplexed stream keyed by symbol | Decouples tick production from UI; multiple subscribers (watchlist rows, ticket, holdings) share one source. |
| Immutable models | `freezed` + `json_serializable` (optional, if generation is stable) or hand-written immutable classes | Avoid accidental mutation of shared price state; keep build runner risk low given the "no extra setup" rule — prefer hand-written models if codegen adds friction. |
| Testing | `flutter_test`, `mocktail` | Unit-test feed math, order validation, holdings aggregation. |

**Decision to make explicit in README:** if codegen (`build_runner`) is used anywhere, `flutter pub get && flutter run` must still work — either commit generated files or avoid codegen entirely. Recommendation: avoid `build_runner` to guarantee the "no extra setup" requirement; use hand-written models and plain `sqflite`/`drift` without generation, or Drift with generated files committed to the repo.

## 3. Mock Market-Data Feed — Design
- Single `MarketDataService` (singleton via Riverpod provider) owns:
  - Current price map `Map<String, Money>` for the 10 symbols, plus previous-close reference for change/change%.
  - A `Timer.periodic` (or multiple independent timers per symbol, jittered) that mutates prices using a bounded random-walk (e.g. ±0.05%–0.3% per tick, occasional mean reversion) and emits a `PriceTick(symbol, ltp, prevClose, ts)`.
  - Exposes `Stream<PriceTick> tickStreamFor(String symbol)` and `Stream<PriceTick> allTicks` (broadcast streams).
- **Tick rate:** configurable constant `ticksPerSecondPerSymbol` (default 1.0), overridable via a debug settings screen/flag for stress testing (target 5+/sec/symbol = 50+/sec aggregate).
- **Single source of truth:** every screen (Watchlist, Market Overview, Ticket, Holdings) reads price state through the same provider — never duplicates price state locally.
- Feed runs regardless of which screen is visible (app-lifetime singleton) so "return to screen → current, not stale" holds by construction.

## 4. Realtime Rendering Strategy
- Each row/cell subscribes narrowly (`ref.watch(priceProvider(symbol))` or `StreamBuilder` scoped per row) so a tick for RELIANCE does not rebuild the TCS row or the list scaffold.
- Use `const` widgets aggressively for static row chrome (symbol label, sort icons).
- Flash animation: a short (150–250ms) color-tween `AnimatedContainer`/`TweenAnimationBuilder` triggered by a per-symbol "last direction" value, not by rebuilding the whole tile.
- For F4 sorting: maintain a sorted list derived via a Riverpod `Provider` that recomputes order (e.g. debounced to ~4–10Hz, not every single tick) to avoid excessive `ListView` reordering thrash while still feeling "live."
- Lists use `ListView.builder` with stable `ValueKey(symbol)` per item so Flutter's diffing avoids full-subtree rebuilds on reorder.

## 5. Money & Decimal Handling
- All prices, quantities × price, wallet balance, P&L computed via integer minor-unit arithmetic (paise) or `Decimal`.
- No `double` used for comparisons that gate order acceptance (avoid `>=`/`<=` float bugs).
- Rounding rule documented once (e.g. round to nearest paisa, banker's rounding) and applied consistently.

## 6. Persistence Requirements
| Data | Store | Notes |
|---|---|---|
| Watchlists + membership + order | SQLite (Drift/sqflite) | Tables: `watchlists(id, name, position)`, `watchlist_stocks(watchlist_id, symbol, position)`. |
| Orders (history) | SQLite | `orders(id, symbol, side, qty, price, value, ts)`. |
| Holdings | SQLite | `holdings(symbol, qty, avg_cost)` — derived/maintained transactionally from orders. |
| Wallet balance | SQLite or `shared_preferences` | Single row/key; must be transactionally consistent with order execution. |
| Settings (tick rate) | `shared_preferences` | Debug-only, not required to persist but nice-to-have. |

All writes on order submission (wallet debit/credit + holding upsert + order insert) happen in a **single DB transaction** to avoid partial-state corruption if the app is killed mid-write.

## 7. Error / Edge-Case Handling
- Insufficient balance, oversell, invalid quantity → inline validation errors, submit button disabled/blocked (see PRD F3).
- Empty watchlist / empty holdings → explicit empty-state widgets.
- Reorder/removal race with incoming ticks → price binding keyed by symbol string, never by list index.
- App start with empty DB (first run) → seed nothing except the 10-symbol universe reference data; user creates their own watchlists.
- Feed producing pathological values (shouldn't go ≤0) → clamp price to a small positive floor.

## 8. Performance Targets
- 50+ ticks/sec aggregate with no dropped frames (target 60fps, acceptable floor ~55fps on mid-range device) on the Market Overview screen while scrolling.
- Holdings screen smooth with all 10 symbols held and sort active.

## 9. Testing Plan
- Unit tests: `Money` arithmetic, order validation rules, holdings avg-cost recalculation, P&L aggregation.
- Widget test: watchlist reorder keeps correct symbol-to-price binding.
- Optional integration test: stress-tick the feed and assert no missed/duplicate UI updates for a sampled symbol.

## 10. CI / Repo Hygiene
- `.gitignore` excludes build artifacts.
- Incremental, message-per-feature commit history (see Implementation Plan.md).
- README documents exact `flutter --version` used, and any platform caveats.
