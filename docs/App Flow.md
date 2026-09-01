# App Flow.md

## 1. Navigation Shell
Bottom navigation (or tab bar) with 3 primary destinations, since Market Overview is a surface and Watchlists/Holdings are the other two persistent tabs; the Ticket is always a pushed screen (never a tab):

```
[ Market ]   [ Watchlists ]   [ Holdings ]
```

Wallet balance is visible persistently in an app bar (top of every tab) since it gates every Buy action.

## 2. Screen-by-Screen Flow

### 2.1 Market Overview (`/market`)
- Entry: app launch default tab, or tab tap.
- Shows all 10 stocks in a live list/grid: symbol, LTP, change, change%, flash on tick.
- Tap a row → pushes **Buy/Sell Ticket** pre-filled with that stock, side unset (user picks Buy/Sell).
- Optional debug affordance (e.g. long-press app bar or a hidden settings icon) → tick-rate control for stress testing.

### 2.2 Watchlists (`/watchlists`)
- **Watchlist List Screen**: shows all watchlists (name, stock count). FAB → "New watchlist" (name input dialog). Swipe/long-press → rename/delete with confirmation.
- Tap a watchlist → **Watchlist Detail Screen** (`/watchlists/:id`):
  - List of stocks in that watchlist, live prices, drag handle for reorder, swipe/remove action.
  - "+ Add stock" → opens **Stock Picker** (bottom sheet) listing the 10 stocks, disabled/checked if already present.
  - Empty state ("No stocks yet — tap + to add") when list is empty.
  - Tap a row → pushes **Buy/Sell Ticket** pre-filled with that stock.

### 2.3 Buy/Sell Ticket (`/ticket`, pushed, not a tab)
- Always arrives with a `Stock` argument (from Market, Watchlist row, or Holdings row) — side may or may not be pre-set depending on entry point.
- Shows: stock symbol/name, live LTP (updating), side toggle (Buy/Sell), quantity field, computed order value (qty × live LTP), available balance (Buy) or held qty (Sell), inline validation.
- Submit:
  - Valid → **Order Confirmation** (`/ticket/confirmation`) showing executed price, qty, value, new balance/holding; "Done" pops back to the screen the user came from (or to Holdings).
  - Invalid → inline error, no navigation.
- Back/cancel at any point discards the draft without side effects.

### 2.4 Holdings (`/holdings`)
- Aggregate summary bar pinned at top: total invested, current value, total P&L (₹, %).
- List of holdings sorted (default P&L desc); sort control (P&L / Symbol / Current Value) in app bar or segmented control.
- Empty state ("No holdings yet — place your first trade") with a shortcut into Market Overview when empty.
- Tap a row → pushes **Buy/Sell Ticket** pre-filled (defaults to Sell is a reasonable UX nicety, but Buy/Sell both available).

## 3. Cross-Cutting Flows

### 3.1 App Launch
1. `main.dart` → `ProviderScope` → DB opened → `MarketDataService` started (feed begins ticking immediately, even before any screen subscribes).
2. Restore: watchlists, wallet balance, holdings, order history all loaded from DB reactively.
3. Default landing tab: Market Overview.

### 3.2 Restart Persistence Check (maps to PRD "expected scenarios")
- Kill and relaunch app → watchlists/order/holdings/wallet must reflect exact pre-kill state (validates transactional writes in TRD §6).

### 3.3 Same Stock, Multiple Surfaces
- RELIANCE shown in 2 watchlists + Market Overview + possibly Holdings simultaneously → all four bind to the same `priceProvider(RELIANCE)`, so a single tick updates all visible instances in the same frame.

### 3.4 Navigate Away and Back
- Leaving Market Overview (e.g. to Watchlists tab) does not stop the feed (app-lifetime singleton); returning shows current, not stale, prices — no manual refresh needed.

## 4. Wireframe-Level Sketch (textual)

```
Market Overview                Watchlist Detail              Buy/Sell Ticket
┌───────────────────┐         ┌───────────────────┐         ┌───────────────────┐
│ Wallet: ₹1,00,000  │         │ ← My Watchlist  + │         │ ← RELIANCE         │
├───────────────────┤         ├───────────────────┤         ├───────────────────┤
│ RELIANCE  2950 ▲   │         │ ≡ RELIANCE 2950 ▲ │         │ LTP: ₹2,950.40 ▲   │
│ TCS       3850 ▼   │         │ ≡ TCS      3850 ▼ │         │ Side: [Buy][Sell]  │
│ INFY      1650 ▲   │         │                    │         │ Qty:  [____]       │
│ ...                │         │  (empty state if   │         │ Value: ₹29,504.00  │
│                    │         │   no stocks)        │         │ Balance: ₹1,00,000 │
└───────────────────┘         └───────────────────┘         │ [Submit]            │
                                                              └───────────────────┘
```

## 5. Error / Empty States Inventory
| Screen | Empty/Error State |
|---|---|
| Watchlist List | "No watchlists yet — create one" |
| Watchlist Detail | "No stocks yet — tap + to add" |
| Holdings | "No holdings yet — place your first trade" |
| Ticket (Buy) | "Insufficient balance for this order" |
| Ticket (Sell) | "You only hold X shares of Y" |
| Ticket (qty) | "Enter a whole number greater than 0" |

---

# 🦅 Kestrel v2 Navigation & App Flow Additions

## 1. Updated 4-Tab Navigation Shell
```
[ Market ]   [ Watchlists ]   [ Orders ]   [ Holdings ]
```
- **Market Tab (`/market`)**: Live 10-stock feed + Search Bar + Sector Filter Chips + Top Gainers / Losers Screener tabs.
- **Watchlists Tab (`/watchlists`)**: Persistent watchlists, drag-and-drop reordering, stock picker modal.
- **Orders Tab (`/orders`)**: Dedicated activity hub for `All`, `Open / Pending` (with instant Cancel button), `Executed`, and `Cancelled` orders.
- **Holdings Tab (`/holdings`)**: Positions list, Realized & Unrealized P&L hero card, and Sector Allocation Donut Chart.

## 2. Updated Ticket & Stock Details Flow (`/ticket/:symbol`)
- Pre-fills stock with live LTP.
- **Technical Chart**: Candlestick / Area Sparkline toggle with timeframe pills (`1D`, `1W`, `1M`, `1Y`, `ALL`) and interactive touch scrubber overlay.
- **L2 Market Depth Ladder**: Top 5 Bids vs Top 5 Asks with animated depth volume bars.
- **Order Type Selector**: Segmented tab between `MARKET`, `LIMIT`, and `STOP-LOSS (SL)`.
- Direct quantity stepper + quick chips (`+1`, `+5`, `+10`, `+25`, `+50`, `MAX`).
- Validation banner & atomic execution / pending order placement with tactile haptics.

## 3. Funds Management Sheet
- Tapping the wallet balance pill opens the **Funds Manager Sheet**:
  - Deposit Demo Capital (+₹50,000, +₹1,00,000).
  - Reset Portfolio to initial ₹1,00,000 demo state.
