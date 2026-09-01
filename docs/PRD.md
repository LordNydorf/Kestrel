# PRD — Flutter Mock Trading App

## 1. Overview
A Flutter mobile app simulating a retail trading experience: watchlists, a live market overview, a buy/sell order ticket, and a holdings/portfolio view — all powered by a single in-app mock market-data feed (no real backend).

**Deadline:** Tuesday, 25 August 2026.
**Submission:** Public GitHub repo, README with run instructions, short Loom/screen-recording walkthrough of all 4 features.

## 2. Goals
- Demonstrate clean architecture and realtime correctness under load (50+ ticks/sec).
- Demonstrate correct money/decimal handling (no floating-point drift).
- Demonstrate thoughtful UI for dense, fast-changing tabular data.
- Demonstrate persistence across app restarts (watchlists, wallet, orders, holdings).

## 3. Non-Goals
- No real brokerage integration, auth, or networking.
- No multi-user support.
- No historical charting / technical indicators (not required by the brief).
- No real-money handling — this is a simulator.

## 4. Universe
Fixed set of 10 NSE symbols, each with a reasonable starting price (₹):

| Symbol | Starting LTP (₹) |
|---|---|
| RELIANCE | 2,950.00 |
| TCS | 3,850.00 |
| INFY | 1,650.00 |
| HDFCBANK | 1,620.00 |
| ICICIBANK | 1,150.00 |
| SBIN | 810.00 |
| ITC | 465.00 |
| LT | 3,600.00 |
| BHARTIARTL | 1,580.00 |
| AXISBANK | 1,090.00 |

## 5. Personas
- **Retail user** exploring stocks, building a watchlist, and simulating trades to track a paper portfolio.

## 6. Features & Requirements

### F1 — Watchlists
- Create, rename, delete multiple watchlists.
- Add stocks via a picker over the fixed 10-symbol universe.
- Reorder (drag) and remove stocks within a watchlist.
- Row shows: symbol, LTP, change, change %; updates live in place.
- Persists across restarts (watchlists + membership + order).
- Tap row → opens Buy/Sell ticket pre-filled.
- Empty state when a watchlist has no stocks.
- Same stock in multiple watchlists shows identical live price everywhere (single source of truth).

### F2 — Live Prices Mimic (Market Overview)
- Grid/list of all 10 stocks: symbol, LTP, change, change %, brief flash (green up / red down) on update.
- Mock feed ticks continuously at a configurable, realistic rate (default e.g. 1 tick/sec/stock, adjustable to 5+ tick/sec/stock for stress testing).
- Feed is the single source of price truth for the whole app (watchlists, ticket, holdings all subscribe to it).
- Only affected cells rebuild — no full-list rebuild per tick.
- Smooth scrolling and updates under stress load (50+ ticks/sec aggregate).
- Prices are current (not stale) when returning to the screen after navigating away.

### F3 — Buy/Sell Ticket
- Pre-fills stock when opened from Watchlist or Holdings row; otherwise stock is selectable.
- Inputs: side (Buy/Sell), quantity (integer, >0).
- Live LTP shown, updates in real time while form is open.
- Order value = quantity × LTP at moment of submit (not at moment of typing).
- Buy: blocked if order value > available wallet balance.
- Sell: blocked if quantity > held quantity for that stock.
- Zero/negative/fractional quantity blocked with inline validation error.
- On success: updates wallet balance, updates/creates holding (weighted avg price on buy), records order in history, navigates to a confirmation screen/state.
- Wallet balance and order history persist across restarts.
- All money math uses fixed-point/decimal-safe arithmetic (integer paise/cents internally), never raw `double` for currency comparisons.

### F4 — Holdings
- List: symbol, qty, avg cost, LTP, current value, P&L (₹ and %), all updating live per tick.
- Sortable by P&L, symbol, current value; default sort P&L descending.
- Sort order re-evaluates live as prices move (a row can cross from loss to gain and reorder).
- Aggregate summary bar: total invested, current value, total P&L (₹ and %) — always equals the sum of visible rows.
- Tap row → Buy/Sell ticket pre-filled.
- Sell reducing qty to 0 removes the holding.
- Empty state when no holdings.
- Persists across restarts.
- Remains smooth with all 10 stocks held and ticking.

## 7. Success Criteria (from brief's "what we look for")
1. Clean, readable code with sensible folder structure.
2. Correct realtime behavior under load — no dropped/stale/misrouted ticks after reorder.
3. Precise money/decimal handling.
4. Explicit error and edge-case handling (validation, empty states, restart integrity).
5. Thoughtful UI for dense data (flash, minimal rebuilds, sort stability).
6. Clear, incremental commit history.

## 8. Out-of-Scope Risks to Flag in README
- Mock feed's randomness model (documented, not "real" market behavior).
- Any simplifications made under the time constraint (see Implementation Plan.md).

---

# 🦅 PRD — Kestrel v2 Expansion

## 1. Goals
- Advance Kestrel from a 4-feature prototype into a complete institutional-grade trading terminal.
- Add interactive technical charting (Candlestick & Sparkline), Level 2 (L2) market depth, Limit/Stop-Loss order trigger engine, dedicated Orders hub, market screener & sector filtering, lifetime realized P&L, portfolio allocation analytics, and tactile haptic feedback.

## 2. v2 Feature Requirements
### F5 — Interactive Technical Charting & Multi-Timeframe Scrubber
- Custom Canvas-rendered Candlestick (OHLC) and Area Sparkline modes.
- Timeframes: `1D`, `1W`, `1M`, `1Y`, `ALL`.
- Interactive scrubber overlay to inspect historical price, time, and OHLC data.

### F6 — Level 2 (L2) Market Depth Ladder
- Top 5 Bids vs Top 5 Asks order book with animated volume progress bars.

### F7 — Limit & Stop-Loss Trigger Engine
- Support for Market, Limit, and Stop-Loss orders.
- Order status: `PENDING`, `EXECUTED`, `CANCELLED`, `REJECTED`.
- In-memory tick-driven matching engine that automatically executes pending orders when price conditions are crossed.

### F8 — Dedicated Orders Activity Hub (`/orders`)
- Filter tabs: `All`, `Pending`, `Executed`, `Cancelled`.
- Pending order cancellation with locked funds release.
- Detailed digital trade receipt modal.

### F9 — Market Screener, Sector Filters & Search
- Search bar by ticker or company name.
- Sector filter chips (`Banking`, `IT`, `Energy`, `FMCG`, etc.).
- Screener tabs (`All`, `Top Gainers`, `Top Losers`, `Most Volatile`).

### F10 — Realized P&L & Sector Allocation Donut
- Lifetime realized P&L accounting on share sales.
- Interactive custom canvas Donut chart visualizing sector exposure and cash ratio.

### F11 — Wallet Simulator Funds Manager
- Deposit demo funds or reset portfolio to initial state.

### F12 — Tactile Haptic Feedback
- Haptic cues across buttons, chips, tabs, and trade executions.

---

# 🅿️ Parking Lot & Future Roadmap (v3 & Beyond)

The following items are deferred from v2 to v3+ to maintain stability and zero-dependency execution:

### 1. Real Broker API & Live Exchange Gateway (v3)
- **Live WebSocket Streams**: Integration with Zerodha Kite Connect, Upstox, or Angel One real-time WebSocket feeds.
- **Broker Authentication**: Secure OAuth2 login and TOTP authentication for real-money execution.

### 2. Cloud Database & Cross-Device Sync (v3)
- **Supabase / Firebase Backend**: Synchronizing watchlists, active positions, and trade history across mobile, tablet, and web clients.
- **Offline Cache First**: Local SQLite persistence with optimistic cloud synchronization.

### 3. Advanced Technical Indicators & Chart Overlays (v3)
- **Mathematical Overlays**: Real-time 20/50/200 Exponential Moving Averages (EMA), Relative Strength Index (RSI 14), Moving Average Convergence Divergence (MACD), Bollinger Bands, and Volume Weighted Average Price (VWAP).
- **Drawing Tools**: Support for horizontal support/resistance lines and Fibonacci retracements.

### 4. Derivatives & Options Chain (v4)
- **Options Trading**: Call/Put option chain with strike ladders, Open Interest (OI) heatmaps, and Option Greeks (Delta, Theta, Gamma, Vega).

### 5. Push Notifications & Price Alerts (v3)
- **Background Price Alerts**: System notifications when target limit prices or stop-loss triggers are reached while the app is closed.

### 6. Biometric Security & PIN Lock (v3)
- **Biometric Gate**: Face ID / Fingerprint / 4-digit PIN authentication on app resume and trade execution confirmation.

