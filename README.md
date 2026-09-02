# 🦅 Kestrel — Real-Time Institutional Mobile Trading Terminal

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-brightgreen)](#)
[![Tests](https://img.shields.io/badge/Tests-80%2B%20Passing%20(100%25)-success)](#)
[![Design](https://img.shields.io/badge/Design-Hallmark%20Obsidian-10B981)](#)
[![Zero Float Drift](https://img.shields.io/badge/Precision-Integer%20Paise-blue)](#)
[![Analysis](https://img.shields.io/badge/Static%20Analysis-0%20Issues-brightgreen)](#)

**Kestrel** is an ultra-high-performance financial trading application engineered with Flutter, Riverpod 2.x, and SQLite. Inspired by institutional Bloomberg and Zerodha terminals, Kestrel delivers hardware-accelerated Custom Canvas technical charting (OHLC Candlesticks & Area Sparklines), Level 2 Market Depth (5-Level Bids vs Asks Order Book), an automated background Limit/Stop-Loss Matching Daemon, institutional Digital Trade Receipts with regulatory fee breakdowns, interactive Sector Allocation Donut Charts, and persistent reorderable watchlists—with zero cumulative layout shift (CLS) and zero floating-point drift.

---

## 🌟 Hallmark Design & Engineering Philosophy

Kestrel is built following the **Hallmark Obsidian Design System**:
- **Dark Obsidian Canvas Palette**:
  - Deep space backdrop (`#0B0F17`), elevated surfaces (`#131B2A`), crisp hairline borders (`#23324D`).
  - Semantic financial colors: Emerald (`#10B981`) for gains/buys, Crimson (`#EF4444`) for losses/sells, Electric Blue (`#3B82F6`) for brand accents.
- **2+1 Typography Discipline**:
  - Headers & Displays: **Space Grotesk** (geometric, sharp legibility).
  - Financial Figures & Prices: **JetBrains Mono** with `fontFeatures: [FontFeature.tabularFigures()]` — ensuring numerical columns never shift during rapid price ticks.
- **Mobile-First Ergonomics**:
  - Pinned sticky bottom trade execution bar (`Scaffold.bottomNavigationBar`) — 100% visible above the fold on all device viewports with zero scrolling required.
  - Generous touch targets ($\ge 48\times 48\text{dp}$) across steppers, chips, and action buttons.
  - Native tactile haptic feedback (`Haptics.selection()`, `Haptics.heavy()`) on taps, order triggers, and speed changes.

---

## 🚀 Complete Feature Catalog

### 1. 📊 Interactive Technical Charting & Canvas Painters (`/ticket/:symbol`)
- **Custom Canvas Hardware Acceleration**: Direct Skia/Impeller Canvas drawing running in $< 4\text{ms}$ per frame ($60+\text{fps}$).
- **Candlestick (OHLC) & Glowing Sparkline Modes**: Seamless toggle between green/red candle bodies with high/low wicks and smooth cubic Bézier area curves.
- **Timeframe Selector**: Hallmark pill selectors (`1D`, `1W`, `1M`, `1Y`, `ALL`) backed by a deterministic OHLC generator.
- **Touch & Drag Crosshair Scrubber**: Scrub horizontally to inspect historical timestamps and dynamic OHLC floating metrics.
- **Technical Indicator Overlays**:
  - **`SMA 20`**: Golden 20-period simple moving average overlay curve.
  - **`Bollinger Bands`**: 20-period moving average with $\pm 2\sigma$ upper/lower volatility bands and translucent ribbon shading.

### 2. 📖 Level 2 (L2) Order Book & Market Depth (`/ticket/:symbol`)
- **5-Level Bid/Ask Ladder**: Top 5 Buyers (descending) vs Top 5 Sellers (ascending) with animated volume depth bars.
- **Sentiment Gauge**: Real-time visual ratio of Total Buying Interest vs Total Selling Interest.

### 3. ⚡ Trade Ticket & Order Execution (`/ticket/:symbol`)
- **Sticky Bottom Action Bar**: Pinned BUY/SELL execution bar displaying calculated order value and available wallet balance—always visible before scrolling.
- **Order Types**: `MARKET`, `LIMIT`, and `STOP-LOSS` (SL) with $\pm ₹1$ quick price nudge chips.
- **Pure Domain Validation**: `OrderValidator` prevents overselling, insufficient funds, and invalid quantities.
- **Atomic SQLite Execution**: Wallet debits/credits, holdings recalculation, and order logging occur within a single ACID transaction.

### 4. ⚙️ Live Background Auto-Matching Daemon (`OrderMatchingDaemon`)
- **Continuous Tick Listener**: Subscribes to real-time market ticks across the 10-symbol universe.
- **Automated Order Fills**: Automatically executes open `PENDING` Limit and Stop-Loss orders in SQLite when market prices cross thresholds.
- **In-App Floating Toasts**: Notifies the trader with an in-app execution snackbar whenever a limit order fills in the background.

### 5. 🧾 Institutional Digital Trade Receipts (`/orders`)
- **Official Settlement Breakdown**: Tap any order card to open the trade receipt modal.
- **Indian Regulatory Statutory Charges Simulator**:
  - Brokerage: ₹0.00 *(Zero Brokerage)*
  - STT / CTT (0.1% on delivery)
  - Exchange Transaction Charges & SEBI Turnover Fees
  - GST (18%) & Stamp Duty (0.015% on buy)
  - Net Settlement Amount (debited / credited).
  - Realized P&L badge for closed positions.

### 6. 💼 Portfolio Holdings & Sector Donut (`/holdings`)
- **Interactive Asset Allocation Donut Chart**: Custom Canvas donut displaying sector distribution (`Banking`, `Technology`, `Energy`, `Cash`) with center portfolio valuation and detailed legend breakdown.
- **Position Details & Quick Actions Sheet**: Tap any position row to view Unrealized P&L, Total Invested, Average Buy Price, and 1-tap **`⚡ Add More` (BUY)** / **`🛑 Square Off` (SELL)** buttons.
- **Lifetime Win Rate Analytics**: Real-time calculation of trading win rate % (`e.g., 80% (4W / 1L)`) and cumulative Realized P&L.
- **Virtual Funds Manager**: Deposit mock paper-trading cash (`+₹50k`, `+₹100k`) or reset your portfolio to ₹1,00,000.

### 7. 🔍 Market Overview Screener & Search (`/market`)
- **Real-Time Symbol Search**: Instant filtering by symbol or company name.
- **Sector Screener Chips**: Filter across `Banking`, `Technology`, `Energy`, `Consumer`, and `Auto`.
- **Gainers / Losers Screener Tabs**: Live re-ranking across `All Instruments`, `Top Gainers`, and `Top Losers`.
- **Feed Speed Simulator**: Configurable tick rate (1.0x Normal @ 10 ticks/s, 2.5x Fast @ 25 ticks/s, 5.0x Turbo @ 50+ ticks/s).

### 8. 📑 Persistent Watchlists (`/watchlists`)
- **SQLite Persistence**: Watchlists and memberships persist across app kills and restarts.
- **Drag & Drop Reordering**: Long press and drag rows with continuous live price bindings.
- **Stock Picker Search**: Search modal with sector badges when adding stocks to watchlists.

---

## 🧮 Integer-Paise Precision Architecture

To eliminate IEEE 754 floating-point rounding errors in financial transactions:
- The [Money](file:///c:/Users/notth/Projects/Kestrel/lib/core/money/money.dart) value object stores all amounts strictly as `int _paise` ($1\text{ Rupee} = 100\text{ paise}$).
- Weighted average cost arithmetic uses integer rounding:
$$\text{newAvgCostPaise} = \left\lfloor \frac{(\text{oldQty} \times \text{oldAvgCostPaise}) + (\text{newQty} \times \text{buyPricePaise})}{\text{oldQty} + \text{newQty}} + 0.5 \right\rfloor$$
- Custom Indian currency formatting outputs compliant strings (`₹1,00,000.00`).

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── constants/symbols.dart          # 10-symbol universe definitions & metadata
│   ├── money/money.dart                # Integer paise precision Money value object
│   ├── theme/app_theme.dart            # Hallmark Obsidian color tokens & 2+1 typography
│   └── utils/haptics.dart              # Native system haptic feedback wrapper
├── data/
│   ├── db/app_database.dart            # SQLite v2 schema (orders v2, wallet locked funds)
│   ├── feed/
│   │   ├── historical_data_service.dart# Deterministic OHLC candle generator
│   │   ├── market_data_service.dart    # High-frequency tick feed generator & streams
│   │   ├── market_depth_service.dart   # Level 2 Order Book synthetic stream generator
│   │   └── price_tick.dart             # Immutable PriceTick model
│   └── repositories/
│       ├── trading_repository.dart     # Atomic trading transactions, limit execution & cancellation
│       └── watchlist_repository.dart   # SQLite watchlist CRUD & reordering
├── domain/
│   ├── models/
│   │   ├── candle_data.dart            # OHLC candle domain model & Timeframe enum
│   │   ├── holding.dart                # Holding domain model
│   │   ├── market_depth.dart           # 5-level Bids vs Asks order book model
│   │   ├── order.dart                  # Order model with OrderType, OrderStatus, realizedPnl
│   │   └── watchlist.dart              # Watchlist model
│   └── services/
│       ├── order_matching_daemon.dart  # Background reactive tick-matching daemon
│       ├── order_matching_engine.dart  # Pure domain limit/SL matching rules
│       ├── order_validator.dart        # Order gating validator
│       └── pnl_calculator.dart         # Portfolio valuation, sector allocation & P&L calculator
├── features/
│   ├── charts/                         # Technical Charting, Candlestick/Sparkline Painters & Indicators
│   ├── holdings/                       # Holdings Screen, Sector Donut, Details Sheet, Summary Card
│   ├── market_depth/                   # L2 Market Depth 5-level ladder widget
│   ├── market_overview/                # Market Screen, PriceCell, Search Bar, Screener Tabs
│   ├── orders/                         # 4th Tab Orders Screen, Digital Receipt Sheet
│   ├── splash/                         # Animated branded launch screen
│   ├── ticket/                         # Trade Screen, Sticky Bottom Bar, Order Type Selector
│   └── watchlists/                     # Watchlist List & Detail Screens, Reorderable rows, Stock Picker
└── routing/
    └── app_router.dart                 # 4-Tab GoRouter shell & daemon event listener
```

---

## 🧪 Automated Test Suite

Kestrel features a comprehensive automated testing suite with **80+ tests passing (100%)**:

```bash
# Run the entire test suite
flutter test

# Run static analysis
flutter analyze
```

### Test Coverage Highlights:
1. **Unit Tests**:
   - `Money` arithmetic, division, and Indian currency formatting.
   - `OrderValidator` (Market, Limit, Stop-Loss gating & shortfall calculation).
   - `OrderMatchingEngine` (Limit BUY/SELL & Stop-Loss execution conditions).
   - `PnlCalculator` (Weighted average cost, unrealized P&L, sector allocation).
2. **Stress Tests (`50+ Ticks/Sec`)**:
   - 10,000 rapid buy/sell arithmetic operations maintaining 0 floating drift.
   - High-load stream buffer stability under 5.0x Turbo feed speed.
   - Race-free concurrent SQLite trade executions.
3. **Widget Tests**:
   - Technical Charting canvas rendering, touch scrubber, and SMA/Bollinger indicators.
   - Level 2 Market Depth ladder rendering and buyer/seller ratio.
   - Digital Trade Receipt modal with statutory fee calculations.
   - Sector Allocation Donut Chart and Holdings quick action sheet.
   - Watchlist drag-and-drop reordering with live price binding integrity.

---

## 🚀 Getting Started

Kestrel runs out of the box with zero code generation requirements:

```bash
# 1. Clone repository
git clone https://github.com/LordNydorf/Kestrel.git
cd Kestrel

# 2. Fetch dependencies
flutter pub get

# 3. Run application
flutter run
```

---

## 🅿️ Future Roadmap (v3 & Beyond)

- **Pluggable Exchange Gateway**: Live WebSocket gateway (`IExchangeFeed`) for Zerodha Kite Connect / Upstox.
- **Cloud Synchronization**: Supabase / Firebase backend for multi-device watchlist and position sync.
- **Off-Thread Compute**: Technical indicator math (EMA, RSI, MACD) offloaded to background Dart `Isolate`s.
- **Biometric Security**: Face ID / Fingerprint gate on app launch and order submission.
