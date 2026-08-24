# 🦅 Kestrel — Real-Time Financial Trading Terminal for Mobile

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-brightgreen)](#)
[![Tests](https://img.shields.io/badge/Tests-49%2F49%20Passing%20(100%25)-success)](#)
[![Design](https://img.shields.io/badge/Design-Hallmark%20Obsidian-10B981)](#)
[![Zero Float Drift](https://img.shields.io/badge/Precision-Integer%20Paise-blue)](#)

**Kestrel** is an ultra high-performance, mobile-first financial trading application built with Flutter, Riverpod, and SQLite. Engineered with a **Technical Instrument** aesthetic, it delivers streaming real-time market data across high-frequency tick simulations (up to 50+ ticks/sec), atomic transactional order execution, persistent reorderable watchlists, and live portfolio P&L calculations with zero cumulative layout shift (CLS).

---

## 🌟 Hallmark Design & Engineering Philosophy

Kestrel is built from the ground up following the **Hallmark Design System**:
- **Dark Obsidian Canvas Palette**:
  - Deep space background (`#0B0F17`), glass-tinted elevated surfaces (`#131B2A`), crisp hairline borders (`#23324D`).
  - Strict semantic colors: Emerald (`#10B981`) for upticks, gains, and BUY actions; Crimson (`#EF4444`) for downticks, losses, and SELL actions.
- **2+1 Typography Discipline**:
  - Primary UI & Headers: **Space Grotesk** (crisp, modern geometric display).
  - Financial Figures & Prices: **JetBrains Mono** with `fontFeatures: [FontFeature.tabularFigures()]` — guaranteeing that numbers never shift or jitter as prices tick rapidly.
- **200ms Micro-Flash Animations**:
  - Live price cells flash subtly on upticks/downticks with ease-out quad curves before settling smoothly back to transparent.
- **Zero Extra Setup Constraint**:
  - Runs out of the box with standard `flutter pub get && flutter run`. No `build_runner` or code-generation scripts required.

---

## 🚀 Key Feature Modules

### 1. 📈 Real-Time Market Overview (`/market`, F2)
- **10-Symbol NSE Universe**: `RELIANCE`, `TCS`, `HDFCBANK`, `INFY`, `ICICIBANK`, `HINDUNILVR`, `ITC`, `SBIN`, `BHARTIARTL`, `KOTAKBANK`.
- **In-Memory Feed Simulation**: Bounded random walk ([-0.25%, +0.25%]) with mean reversion and an absolute positive floor (clamped at ₹1.00).
- **Isolated Repaints**: Each stock cell listens exclusively to its individual symbol tick stream. Ticking `RELIANCE` never causes `TCS` or parent screens to rebuild.
- **Speed Simulator & Stress Tester**: Interactive AppBar speed toggle (1.0x Normal @ 10 ticks/s, 2.5x Fast @ 25 ticks/s, 5.0x Turbo @ 50+ ticks/s).

### 2. 📑 Persistent & Reorderable Watchlists (`/watchlists`, F1)
- **SQLite Local Persistence**: Powered by SQLite with strict foreign key constraints and `ON DELETE CASCADE`. All watchlists, custom names, and custom stock orders persist across app restarts.
- **Drag-and-Drop Reordering**: Long press and drag rows with `ReorderableListView.builder`. Price tick subscriptions remain bound to stock symbols during and after reordering.
- **Stock Picker Bottom Sheet**: Add any stock from the 10-symbol universe with duplicate prevention and live badge states.
- **Swipe-to-Remove**: Seamless dismissible swipe gestures to remove stocks from active watchlists.

### 3. 🎫 Buy/Sell Trade Ticket & Atomic Execution (`/ticket/:symbol`, F3)
- **Pure Domain Validation**: `OrderValidator` instantly gates orders:
  - BUY orders require `OrderValue <= WalletBalance` (shortfall warnings display exact required cash).
  - SELL orders require `Quantity <= HeldShares` (displays warning if unowned).
- **Live Calculation**: Tabular-nums compute order values in real-time (`Quantity × Current Live Price`) with zero CLS.
- **Stepper & Quick Chips**: Increment/decrement stepper (`-`, `+`) and quick chips (`+1`, `+5`, `+10`, `+25`, `+50`, `+100`, `MAX`).
- **Atomic Execution in SQLite**: Single transaction debits/credits wallet, recalculates weighted average cost on buys, decrements/removes holdings on sells, and logs order receipts.
- **Order Confirmation Receipt**: Animated receipt card displaying Order ID, execution price, quantity, total amount, and remaining cash balance.

### 4. 💼 Portfolio Holdings & Real-Time P&L (`/holdings`, F4)
- **Hero Portfolio Summary Card**:
  - Live Total Current Valuation, Total Invested Amount, Available Cash, and Overall Unrealized P&L in absolute ₹ and percentage.
- **Live-Updating Position Rows**:
  - Displays Symbol, Share Count, Average Buy Price, Current Live Value, and individual Unrealized P&L with live tick flashes.
  - Tapping any holding opens its Trade Ticket directly.
- **Debounced Sorting Options**:
  - Sort by `P&L (High → Low)`, `P&L (Low → High)`, `Symbol (A → Z)`, or `Value (High → Low)`.

---

## 🧮 Integer-Paise Precision Architecture

To completely eliminate IEEE 754 floating-point drift in financial transactions:
- The [Money](file:///c:/Users/notth/Projects/Kestrel/lib/core/money/money.dart) domain value object stores all amounts strictly as `int _paise` ($1\text{ Rupee} = 100\text{ paise}$).
- Division and weighted average cost arithmetic use explicit round-to-nearest integer paise:
$$\text{newAvgCostPaise} = \left\lfloor \frac{(\text{oldQty} \times \text{oldAvgCostPaise}) + (\text{newQty} \times \text{buyPricePaise})}{\text{oldQty} + \text{newQty}} + 0.5 \right\rfloor$$
- Custom Indian numbering formatter outputs compliant `en_IN` currency strings (e.g. `₹1,00,000.00`).

---

## 📂 Project Architecture

```
lib/
├── core/
│   ├── constants/
│   │   └── symbols.dart          # 10 NSE symbols definition & universe metadata
│   ├── money/
│   │   └── money.dart            # Integer paise precision value object
│   └── theme/
│       └── app_theme.dart        # Hallmark color tokens & 2+1 typography
├── data/
│   ├── db/
│   │   └── app_database.dart     # SQLite schema (watchlists, stocks, wallet, orders, holdings)
│   ├── feed/
│   │   ├── market_data_service.dart # High-frequency tick generator & streams
│   │   └── price_tick.dart       # Immutable PriceTick model
│   └── repositories/
│       ├── trading_repository.dart  # Atomic SQLite trading transactions & reactive streams
│       └── watchlist_repository.dart# SQLite watchlist CRUD & reordering
├── domain/
│   ├── models/
│   │   ├── holding.dart          # Holding domain entity
│   │   ├── order.dart            # Order domain entity
│   │   └── watchlist.dart        # Watchlist domain entity
│   └── services/
│       ├── order_validator.dart  # Pure domain order validation engine
│       └── pnl_calculator.dart   # Portfolio valuation & unrealized PnL calculator
├── features/
│   ├── holdings/
│   │   ├── providers/            # Riverpod portfolio summary & sort providers
│   │   ├── screens/              # HoldingsScreen with empty & populated states
│   │   └── widgets/              # PortfolioSummaryCard & live HoldingRow
│   ├── market_overview/
│   │   ├── providers/            # Price tick providers & simulation rate controller
│   │   ├── screens/              # MarketOverviewScreen with speedometer dialog
│   │   └── widgets/              # Zero-CLS PriceCell with 200ms micro-flash
│   ├── ticket/
│   │   ├── providers/            # Trading controller & validation providers
│   │   └── screens/              # TicketScreen & OrderConfirmationScreen
│   └── watchlists/
│       ├── providers/            # Watchlist CRUD & reactive stream providers
│       ├── screens/              # WatchlistListScreen & WatchlistDetailScreen
│       └── widgets/              # StockPickerSheet & WatchlistRow
├── routing/
│   └── app_router.dart           # GoRouter configuration & bottom navigation shell
├── app.dart                      # Root MaterialApp with dark theme
└── main.dart                     # App entry point
```

---

## 🧪 Comprehensive Test Suite (49/49 Tests Passing)

Kestrel includes complete unit, contract, widget, and high-frequency stress tests:

```bash
flutter test
```

### Test Breakdown:
- **`test/core/money_test.dart` (7 tests)**:
  - Integer paise precision, arithmetic addition/subtraction, multiplication/division rounding, comparison operators, and `en_IN` currency formatting.
- **`test/domain/order_validator_test.dart` (6 tests)**:
  - Pure validation for insufficient wallet funds, zero/negative quantities, and short-selling restrictions.
- **`test/domain/pnl_calculator_test.dart` (5 tests)**:
  - Portfolio aggregate calculations, single/multi-asset weighted gains & losses, empty portfolio edge cases.
- **`test/data/market_data_service_test.dart` (5 tests)**:
  - Universe starting prices, broadcast streams, symbol filters, snapshot lookups, rate throttle adjustments.
- **`test/data/watchlist_repository_test.dart` (7 tests)**:
  - SQLite persistence, CRUD operations, duplicate prevention, cascade deletions, transactional reordering.
- **`test/data/trading_repository_test.dart` (7 tests)**:
  - Atomic BUY/SELL execution, wallet balance debits/credits, weighted average cost recalculation.
- **`test/data/stress_test.dart` (4 tests)**:
  - 500+ rapid ticks at 50 ticks/sec without stream buffer overrun, 10,000 rapid buy/sell operations with 0 float drift, concurrent multi-asset race-free execution, high-load validator throughput.
- **`test/features/watchlists_screen_test.dart` (4 tests)**:
  - Empty state, creation modal, stock picker modal sheet, drag-and-drop row binding.
- **`test/features/ticket_screen_test.dart` (3 tests)**:
  - Live calculation, BUY order placement, confirmation receipt, SELL validation gating.
- **`test/features/holdings_screen_test.dart` (3 tests)**:
  - Empty state with CTA, populated portfolio summary, sort menu criteria updates.
- **`test/widget_test.dart` (1 test)**:
  - Market overview smoke test across all 10 symbols.

---

## 🛠️ Getting Started

### Prerequisites:
- Flutter SDK (3.x or higher)
- Android Studio / Xcode (configured for Android / iOS)

### Installation & Run:
```bash
# 1. Clone the repository
git clone https://github.com/LordNydorf/Kestrel.git
cd Kestrel

# 2. Install dependencies
flutter pub get

# 3. Verify static analysis (0 issues)
flutter analyze

# 4. Run automated test suite (49/49 passing)
flutter test

# 5. Launch application on connected emulator or device
flutter run
```
