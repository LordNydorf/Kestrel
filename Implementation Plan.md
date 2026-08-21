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
- [ ] Restart restores watchlists + stock membership + order
- [ ] Reorder keeps correct live-price binding per row (no stale/misrouted ticks)
- [ ] Removed stock stops updating and is gone after restart
- [ ] Same stock in 2 watchlists shows identical live price
- [ ] Empty watchlist shows empty state
- [ ] Tapping a watchlist row opens ticket pre-filled
- [ ] Only affected cells rebuild on tick (verify via DevTools rebuild highlighting)
- [ ] Scrolling stays smooth during ticks
- [ ] Stress tick rate (50+/sec aggregate) → no visible freeze/drop
- [ ] Up vs down flash color differs
- [ ] Leaving and returning to a screen shows current, not stale, prices
- [ ] LTP + order value update live while ticket is open
- [ ] Order value > balance → submit blocked with clear error
- [ ] Successful Buy: balance decreases correctly, holding created/avg-cost updated
- [ ] Oversell blocked
- [ ] Fractional/negative/zero qty blocked
- [ ] No visible floating-point drift in any displayed number
- [ ] Buy appears in Holdings (new row or updated qty/avg cost)
- [ ] Sell to zero removes holding
- [ ] P&L updates without full-list re-render
- [ ] Sort by P&L reorders live as prices cross gain/loss
- [ ] Aggregate summary always equals sum of rows
- [ ] All 10 stocks held → smooth scroll + updates

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
