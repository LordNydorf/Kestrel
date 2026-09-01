# Architecture.md

## 1. Architectural Style
Layered, feature-first architecture with unidirectional data flow:

```
UI (widgets) → Providers/Controllers (Riverpod) → Repositories → Data Sources (Feed / DB)
                       ↑____________________ streams/state ____________________|
```

- **Presentation layer**: dumb-ish widgets, watch narrow providers, dispatch intents (e.g. `submitOrder()`).
- **Application layer**: Riverpod `Notifier`/`AsyncNotifier` controllers holding business logic (order validation, sort computation).
- **Domain layer**: plain Dart models (`Stock`, `Money`, `Order`, `Holding`, `Watchlist`, `PriceTick`) with no Flutter/DB imports.
- **Data layer**: `MarketDataService` (the mock feed) and `*Repository` classes wrapping Drift/sqflite.

## 2. Folder Structure

```
lib/
  main.dart
  app.dart                     # MaterialApp, routing, ProviderScope

  core/
    money/
      money.dart                # Money value type (int minor units)
    constants/
      symbols.dart               # fixed 10-symbol universe + starting prices
    theme/
      app_theme.dart

  data/
    feed/
      market_data_service.dart   # tick generator, broadcast streams
      price_tick.dart
    db/
      app_database.dart          # Drift/sqflite setup
      tables/
        watchlists_table.dart
        orders_table.dart
        holdings_table.dart
    repositories/
      watchlist_repository.dart
      order_repository.dart
      holdings_repository.dart
      wallet_repository.dart

  domain/
    models/
      stock.dart
      watchlist.dart
      order.dart
      holding.dart
    services/
      order_validator.dart       # pure functions: balance check, qty check
      pnl_calculator.dart        # pure functions: P&L, aggregates

  features/
    watchlists/
      providers/
      screens/
        watchlist_list_screen.dart
        watchlist_detail_screen.dart
        stock_picker_sheet.dart
      widgets/
        watchlist_row.dart
    market_overview/
      providers/
        price_provider.dart      # per-symbol stream provider, feed off MarketDataService
      screens/
        market_overview_screen.dart
      widgets/
        price_cell.dart          # self-contained, flashes on tick
    ticket/
      providers/
        order_form_controller.dart
      screens/
        buy_sell_ticket_screen.dart
        order_confirmation_screen.dart
    holdings/
      providers/
        holdings_provider.dart
      screens/
        holdings_screen.dart
      widgets/
        holding_row.dart
        holdings_summary_bar.dart

  routing/
    app_router.dart              # go_router (or Navigator 2.0) routes + arg passing (symbol prefill)

test/
  domain/
  data/
  widget/
```

## 3. Data Flow — Price Ticks (the critical path)
1. `MarketDataService` runs one periodic timer (or per-symbol timers) and mutates an internal `Map<String, PriceState>`.
2. On each mutation it pushes a `PriceTick` into a broadcast `StreamController`.
3. `priceProvider(symbol)` (a Riverpod `StreamProvider.family`) filters/maps the broadcast stream to that symbol only.
4. Any widget needing a live price does `ref.watch(priceProvider(symbol))` — Riverpod ensures only that widget subtree rebuilds.
5. Aggregated views (Holdings summary, sorted Holdings list) derive from a `Provider` that combines `holdingsProvider` (DB-backed) with the price map, recomputed via `ref.watch` composition — kept cheap by only touching symbols actually held.

This design directly satisfies: single source of truth (F2), correct rebinding after reorder (F1 — bound by symbol, not index), no full-list rebuild per tick (F2/F4), live updates on Ticket (F3).

## 4. Data Flow — Order Submission
1. `BuySellTicketScreen` collects side + qty, watches `priceProvider(symbol)` for live LTP display.
2. On submit, `OrderFormController.submit()`:
   a. Reads the *current* LTP synchronously from `MarketDataService` (not the last-rendered value, to avoid stale-frame race).
   b. Calls `OrderValidator` (pure function) with wallet balance / held qty.
   c. If valid: opens a DB transaction → insert order row, upsert holding (recompute avg cost on buy), update wallet balance.
   d. On success, navigates to confirmation; on failure, returns a typed validation error the UI renders inline.

## 5. State Management Rationale (Riverpod)
- `StreamProvider.family<PriceTick, String>` per symbol → natural fit for the feed.
- `NotifierProvider`/`AsyncNotifier` for controllers with side effects (order submission, watchlist CRUD).
- `ref.select` used in list rows to depend only on the specific field needed (e.g. LTP), minimizing rebuild scope further.
- No `setState`-driven price UI — all live values flow through providers so scoping is explicit and testable.

## 6. Persistence Architecture
- Drift (or plain `sqflite`) as the single local database, opened once at app start via a provider (`appDatabaseProvider`) and injected into repositories.
- Repositories expose `Stream`s of domain models (Drift supports reactive queries) so UI reflects DB changes without manual refresh.
- Wallet balance stored either as a single-row table (transactional consistency with orders) or `shared_preferences` if kept simple — TRD recommends single-row table for transactional safety with order execution.

## 7. Navigation
- `go_router` recommended for named routes + typed extras (passing a prefilled `Stock` into the ticket route) and deep, testable navigation state.
- Routes: `/watchlists`, `/watchlists/:id`, `/market`, `/ticket` (extra: `Stock`, optional `side`), `/ticket/confirmation`, `/holdings`.

## 8. Why This Structure
- **Feature-first** folders keep each of the 4 required features independently reviewable (maps directly to grading rubric).
- **Domain layer has zero Flutter/DB imports** → business logic (order validation, P&L math) is unit-testable without widget/DB harnesses.
- **Single feed service** enforced architecturally (not by convention) — every price-consuming provider derives from `MarketDataService`, making the "single source of truth" requirement structurally guaranteed rather than merely observed.

---

# 🦅 Architecture Additions for Kestrel v2

## 1. Layered Additions & Modules
- **Charts Module** (`lib/features/charts/`): CustomPainter for Candlestick and Sparkline rendering + `HistoricalDataService`.
- **Market Depth Module** (`lib/features/market_depth/`): `MarketDepthService` and `MarketDepthLadder` widget.
- **Limit Order Engine** (`lib/domain/services/order_matching_engine.dart`): Pure domain evaluator subscribing to `MarketDataService` ticks.
- **Orders Module** (`lib/features/orders/`): `OrdersScreen`, `OrderCard`, and `DigitalReceiptDialog`.
- **Allocation Donut** (`lib/features/holdings/widgets/allocation_donut_chart.dart`): Sector distribution Canvas painter.
- **Haptics Utility** (`lib/core/utils/haptics.dart`): System haptic feedback wrapper.

## 2. Updated Database Schema (Orders v2 & Wallet)
- `orders`: added `type`, `status`, `trigger_price_paise`, `realized_pnl_paise`, `executed_at`.
- `wallet`: added `locked_paise` for pending limit buy orders.
