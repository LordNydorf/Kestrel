# Implementation Plan.md

**Today:** Friday, 21 August 2026. **Deadline:** Tuesday, 25 August 2026 — this is a ~4-day window, so the plan is deliberately front-loaded on the riskiest technical piece (the feed + realtime rendering) and back-loaded on polish, with a hard buffer for the walkthrough video and README.

## Guiding Principle
Get a thin vertical slice of all 4 features working end-to-end early (even ugly), then iterate — do not build one feature to "done" before starting the next. This de-risks the deadline: a submission with 4 rough-but-complete features scores better than 2 polished features and 2 missing ones.

## Day 1 — Fri 21 Aug: Foundation + Feed
- Repo init, Flutter project scaffold, folder structure (per Architecture.md), commit.
- `core/money`, `core/constants/symbols` (10 stocks + starting prices).
- `MarketDataService`: tick generation, broadcast streams, configurable tick rate. **This is the highest-risk, highest-leverage piece — get it right first.**
- Minimal `MarketOverviewScreen` wired to the feed to visually confirm ticks flow and flash correctly.
- Commit checkpoint: "feed + market overview MVP."

## Day 2 — Sat 22 Aug: Persistence + Watchlists
- DB setup (Drift/sqflite), tables for watchlists, orders, holdings.
- Watchlist List + Detail screens: create/rename/delete, add via picker, reorder (drag), remove.
- Wire watchlist rows to the same `priceProvider` as Market Overview (prove single-source-of-truth).
- Verify restart persistence manually (kill app, relaunch, confirm data restored).
- Commit checkpoint: "watchlists + persistence."

## Day 3 — Sun 23 Aug: Ticket + Holdings
- `OrderValidator` + `PnlCalculator` (pure, unit-tested).
- Buy/Sell Ticket screen: prefill, live LTP, validation, submit transaction (wallet + holding + order in one DB transaction).
- Order Confirmation screen.
- Holdings screen: list, sort (P&L/symbol/value), aggregate summary bar, empty state.
- Wire "tap row → ticket" from Watchlist, Market Overview, and Holdings.
- Commit checkpoint: "ticket + holdings, full loop working."

## Day 4 — Mon 24 Aug: Hardening + Performance + Polish
- Stress-test tick rate at 5+/sec/symbol; profile with Flutter DevTools; fix any jank (scoping rebuilds, `const` widgets, sort recompute throttling).
- Edge cases pass: empty states, fractional/negative/zero qty, oversell, insufficient balance, reorder-then-tick correctness, duplicate-stock-across-watchlists price consistency.
- Visual polish per Design Brief.md (flash consistency, tabular numbers, empty states copy).
- Write unit tests for money math, order validation, P&L aggregation.
- Commit checkpoint: "hardening + tests."

## Day 5 (buffer) — Tue 25 Aug: Submission Day
- Final full manual pass through all "Expected scenarios" listed in the brief (use as a literal checklist — see §2 below).
- Write README.md (setup, architecture summary, known limitations, how the mock feed works, how to change tick rate).
- Record Loom/screen-recording walkthrough: one continuous take demonstrating each feature end-to-end per the checklist.
- Push, verify public repo builds clean from a fresh clone (`flutter pub get && flutter run`, no extra steps) — ideally test this on a second machine or ask someone else to try it.
- Submit before end of day, with margin — do not target the deadline itself.

## Expected-Scenarios Checklist (run literally, from the brief)
- [x] Restart restores watchlists + stock membership + order
- [x] Reorder keeps correct live-price binding per row (no stale/misrouted ticks)
- [x] Removed stock stops updating and is gone after restart
- [x] Same stock in 2 watchlists shows identical live price
- [x] Empty watchlist shows empty state
- [x] Tapping a watchlist row opens ticket pre-filled
- [x] Only affected cells rebuild on tick (verify via DevTools rebuild highlighting)
- [x] Scrolling stays smooth during ticks
- [x] Stress tick rate (50+/sec aggregate) → no visible freeze/drop
- [x] Up vs down flash color differs
- [x] Leaving and returning to a screen shows current, not stale, prices
- [x] LTP + order value update live while ticket is open
- [x] Order value > balance → submit blocked with clear error
- [x] Successful Buy: balance decreases correctly, holding created/avg-cost updated
- [x] Oversell blocked
- [x] Fractional/negative/zero qty blocked
- [x] No visible floating-point drift in any displayed number
- [x] Buy appears in Holdings (new row or updated qty/avg cost)
- [x] Sell to zero removes holding
- [x] P&L updates without full-list re-render
- [x] Sort by P&L reorders live as prices cross gain/loss
- [x] Aggregate summary always equals sum of rows
- [x] All 10 stocks held → smooth scroll + updates

## Commit Discipline
Aim for one commit per meaningful checkpoint above, not one giant commit — this directly serves the "clear commit history" grading criterion. Suggested cadence: setup → feed → market overview → db schema → watchlists CRUD → reorder/remove → ticket form → order execution → holdings list → sort/aggregate → perf pass → tests → docs.

## Risk Register
| Risk | Mitigation |
|---|---|
| Realtime perf under stress (50+ ticks/sec) | Build feed + rendering scoping on Day 1, profile early, not on Day 4 |
| Running out of time for polish | Vertical-slice approach ensures all 4 features exist end-to-end by Day 3 |
| `flutter run` failing on a clean clone | Avoid `build_runner`/codegen where possible; test fresh clone before submission |
| Float/decimal bugs surfacing late | `Money` type built and unit-tested on Day 1–2, used everywhere from the start |
| Video/README rushed at the very end | Dedicated Day 5 buffer, not squeezed into Day 4 |

---

# 🦅 Kestrel v2 Expansion Plan

## 1. Scope & Goals for v2
Kestrel v2 evolves the terminal into an institutional-grade financial trading platform:
- **Interactive Technical Charting**: Custom Canvas Candlestick (OHLC) & Area Sparkline charts with touch scrubber.
- **Level 2 (L2) Market Depth**: Top 5 Bids vs Top 5 Asks order book ladder with live volume bars.
- **Limit & Stop-Loss (SL) Trigger Engine**: Support for Limit/Stop-Loss orders with in-memory tick-matching auto execution.
- **Dedicated Orders Activity Screen (`/orders`)**: Open pending orders, executed history, order cancellation, digital receipts.
- **Market Screener & Sector Filter**: Full-text search, sector pills, and Top Gainers / Losers / Volatility screener.
- **Realized P&L & Portfolio Allocation**: Lifetime realized gains/loss, win rate, and sector allocation donut chart.
- **Wallet Funds Manager**: Deposit demo capital and reset portfolio sheet.
- **Tactile Haptics**: Subtle vibrations on stepper clicks, tabs, and trade execution.

## 2. Phased v2 Milestones
- **Phase 1: Domain, Database & Synthetic Generators**
  - Add `OrderType` (`market`, `limit`, `stopLoss`), `OrderStatus` (`pending`, `executed`, `cancelled`), `realizedPnl`, `triggerPrice`.
  - Update SQLite `orders` schema and `TradingRepository`.
  - Implement `HistoricalDataService` (OHLC generator across 1D, 1W, 1M, 1Y, ALL) and `MarketDepthService` (L2 book generator).
- **Phase 2: Technical Charting & L2 Depth UI**
  - Implement `CandlestickPainter` and `SparklinePainter` custom painters.
  - Build `TechnicalChart` with timeframe selector and touch scrubber.
  - Build `MarketDepthLadder` widget.
- **Phase 3: Limit Order Trigger Engine & Execution**
  - Implement `OrderMatchingEngine` pure domain evaluator.
  - Wire tick feed to trigger engine for automated execution and funds locking/releasing.
- **Phase 4: Orders Activity Screen & Screener UI**
  - Update bottom navigation shell to 4 tabs (`Market`, `Watchlists`, `Orders`, `Holdings`).
  - Build `OrdersScreen` with Pending/Executed filters and cancellation action.
  - Add search bar, sector chips, and Gainers/Losers screener to `MarketOverviewScreen`.
- **Phase 5: Portfolio Allocation Donut, Wallet Manager & Haptics**
  - Build `AllocationDonutChart` for sector exposure and cash ratio.
  - Add Realized P&L badge to `PortfolioSummaryCard`.
  - Build `FundsManagerSheet` (deposit demo funds / reset portfolio).
  - Add tactile haptics across interactions.
- **Phase 6: Testing & Polish**
  - Automated unit tests for order matching, historical data, and repository v2.
  - Verification with `flutter analyze` and `flutter test`.

---

# 🅿️ Parking Lot & Future Roadmap (v3 & Beyond)

### Phase v3.1: Live Broker WebSocket Feed & Exchange Gateway
- Replace or complement in-memory simulation with live WebSocket gateway (`IExchangeFeed`) supporting Kite Connect / Upstox.
- OAuth2 token management and auto-reconnection state machine.

### Phase v3.2: Supabase / Firebase Cloud Sync
- Remote cloud PostgreSQL database with Row Level Security (RLS).
- Realtime replication of watchlists and portfolio balances across mobile, tablet, and web.

### Phase v3.3: Advanced Technical Indicators & Background Isolates
- Indicator computation engine offloaded to Dart background `Isolate`s (EMA 20/50/200, RSI 14, MACD, Bollinger Bands, VWAP).
- Interactive indicator toggle overlay on `TechnicalChart`.

### Phase v3.4: Background Price Alerts & Push Notifications
- Local & remote push notifications when limit targets or stop-loss thresholds trigger while app is minimized.

### Phase v3.5: Biometric PIN / Fingerprint Security
- `local_auth` biometric gate for app unlock and order submission confirmation.

