# Design Brief.md — Kestrel Trading UI

<!-- Hallmark · genre: modern-minimal / technical · macrostructure: Trading Terminal · theme: Cobalt/Slate · motion: disciplined -->

## 1. Design Philosophy & Hallmark Alignment
Trading interfaces demand extreme clarity, immediate visual hierarchy, and absolute stability. Every pixel must serve the user's decision-making under fast-moving market conditions. Kestrel rejects generic AI design tropes (no decorative rainbow gradients, no glassmorphism blur, no floating card clutter, no layout shift) in favor of a **modern-minimal technical instrument** aesthetic inspired by the Bloomberg/Linear school of precision UI.

---

## 2. Typography System (The 2+1 Discipline)
Fast-moving numeric data requires strict tabular stability so numbers never jitter or cause reflow as digit counts shift.

- **Primary UI / Headers**: Modern geometric grotesque with tight tracking (`Space Grotesk` or `Geist Sans`, weights 500/700).
- **Tabular Data / Numeric Figures (The Outlier)**: Dedicated engineering monospaced face (`JetBrains Mono` / `Geist Mono` with `tabular-nums` alignment). Applied to all LTP, change, change %, quantity, portfolio value, and P&L figures.
- **Scale (Major Third 1.25)**:
  - Hero / Aggregate P&L: `24–28sp` (bold, dominant)
  - Section Headers / Symbol Titles: `16–18sp` (semi-bold)
  - Row LTP / Values: `14–15sp` (tabular mono, medium)
  - Captions / Change % / Meta: `11–12sp` (tabular mono, regular)
- **Hierarchy Rule**: Maximum 4 type sizes per screen. Visual distinction is driven by weight and color contrast, not random size proliferation.

---

## 3. Color Palette & Token Discipline (OKLCH-Calibrated)
A dark-first, low-fatigue palette with tinted neutrals. No dead pure `#000000` or stark `#FFFFFF`.

| Token | Hex / Spec | Semantic Role |
|---|---|---|
| `--color-paper` | `#0B0F17` / `oklch(12% 0.01 240)` | Base terminal canvas |
| `--color-surface` | `#131B2A` / `oklch(16% 0.015 240)` | Row background & card container |
| `--color-surface-hover` | `#1A2438` / `oklch(20% 0.02 240)` | Interactive row/button hover state |
| `--color-border` | `#23324D` / `oklch(26% 0.02 240)` | Subtle hairlines and cell dividers |
| `--color-ink` | `#F1F5F9` / `oklch(96% 0.005 240)` | Primary symbols, active values, headers |
| `--color-muted` | `#94A3B8` / `oklch(70% 0.01 240)` | Labels, secondary descriptions, timestamps |
| `--color-gain` | `#10B981` / `oklch(68% 0.17 150)` | Positive price ticks, gains, Buy CTA |
| `--color-gain-tint` | `#064E3B` (20% opacity) | Subtle tick flash for price upticks |
| `--color-loss` | `#EF4444` / `oklch(62% 0.20 25)` | Negative price ticks, losses, Sell CTA |
| `--color-loss-tint` | `#7F1D1D` (20% opacity) | Subtle tick flash for price downticks |
| `--color-accent` | `#3B82F6` / `oklch(62% 0.19 250)` | Active tab indicators, focus rings, primary links |

> [!IMPORTANT]
> **Accessibility & Redundancy**: Color is **never** the sole indicator of gain/loss. Every positive/negative movement is paired with an explicit glyph (`▲` / `▼`) and a signed number (`+₹...` / `-₹...`).

---

## 4. Realtime Micro-Interactions & Motion Budget
Motion in Kestrel is strictly functional, never decorative. All transitions adhere to a strict timing budget to avoid distracting the trader.

- **Tick Micro-Flash**:
  - Duration: **180ms–220ms** with exponential ease-out curve (`Curves.easeOutQuad`).
  - Implementation: Transient background tint or left-edge accent indicator that rapidly fades back to `--color-surface`.
  - Scoping: Scoped exclusively to the ticking `PriceCell` widget. Unaffected sibling rows, list containers, and app bars never trigger a re-render.
- **Zero Layout Shift (CLS = 0)**:
  - Numeric columns are fixed-width and right-aligned with tabular figures. Changing from `₹999.50` to `₹1,000.20` causes zero horizontal reflow.
- **Live Reordering & Throttling**:
  - Dynamic sort re-evaluations on the Holdings view are throttled/debounced (4–8 Hz) to maintain 60 FPS without scroll thrashing as prices fluctuate across gain/loss thresholds.

---

## 5. Screen Information Architecture & Hierarchy

### 5.1 Market Overview (`/market`)
- **Top Bar**: Persistent portfolio wallet balance pill with live cash availability. Stress-test tick-rate toggle accessible via header action.
- **Stock Row (48–52dp height)**:
  - *Left*: Symbol (bold, `--color-ink`) + Company subtitle (`--color-muted`).
  - *Right*: Live LTP (bold tabular mono) stacked above Change & Change % with `▲`/`▼` glyph.
- **Interaction**: Tap row opens pre-filled Buy/Sell Ticket.

### 5.2 Watchlists (`/watchlists` & `/watchlists/:id`)
- **Watchlist List**: Clean card tiles showing watchlist name, stock count, and aggregate movement. FAB for new watchlist.
- **Watchlist Detail**:
  - Drag handle on left for reordering (minimum 44x44dp tap target).
  - Swipe-to-delete with red tactile background reveal.
  - "+ Add Stock" triggers a modal bottom sheet displaying the 10-symbol universe with existing members disabled/checked.
  - Empty state with clear call to action when a list has no stocks.

### 5.3 Buy/Sell Ticket (`/ticket`)
- **Header**: Selected Stock, current live LTP (ticking live with flash micro-interaction).
- **Segmented Action Toggle**: Crisp full-width pill switch between **Buy** (Green) and **Sell** (Red).
- **Quantity Input**: Focused numeric input with inline stepper/quick-quantity buttons (1, 5, 10, 50, 100).
- **Calculated Order Value**: Live `qty × current_LTP` computed and displayed in real-time.
- **Safety Context**: Available cash balance (on Buy) or held quantity (on Sell) displayed directly above the action button.
- **Inline Validation**: Immediate, contextual error messaging (e.g. *"Exceeds cash balance by ₹2,450.00"* or *"You hold 0 shares of TCS"*); CTA button disabled when invalid.

### 5.4 Holdings / Portfolio (`/holdings`)
- **Pinned Summary Bar**: Elevated aggregate card displaying:
  - Total Current Value (Hero metric)
  - Total Invested & Total Unrealized P&L (₹ and %)
- **Holdings Table / Cards**:
  - Symbol & Held Quantity
  - Average Cost vs Live Market Price
  - Total Value & Unrealized P&L (colored + signed)
- **Sort Controls**: Tabular segmented bar (Sort by P&L %, Current Value, Symbol).
- **Tap Action**: Opens pre-filled Ticket in Sell mode.

---

## 6. Comprehensive 8-State UI Discipline
Every interactive control (Buttons, Inputs, Row items, Toggles) must implement all 8 states cleanly:

1. **Default**: Crisp border, muted background, clear ink.
2. **Hover (Desktop / Web)**: `--color-surface-hover` subtle lift, cursor pointer.
3. **Focus-Visible**: 2px high-contrast `--color-accent` focus ring with 2px offset.
4. **Active / Pressed**: Subtle scale down (0.98x) and surface deepening.
5. **Disabled**: Reduced opacity (40%), inert to taps, clear explanatory tooltip/context.
6. **Loading**: Inline indeterminate spinner or skeleton pulse without layout jump.
7. **Error**: High-contrast `--color-loss` border and specific contextual helper message.
8. **Success**: Subtle transient green confirmation checkmark / success banner.

---

## 7. Self-Audit Checklist (Hallmark Slop-Test Gates)
- [ ] Are prices and numbers set in tabular monospaced figures without horizontal shift?
- [ ] Is gain/loss always indicated by both color AND directional glyphs/signs?
- [ ] Is the primary accent color constrained to under 3% of the viewport?
- [ ] Are backgrounds and neutrals tinted with subtle chroma (no dead `#000` or pure `#fff`)?
- [ ] Are all tick animations under 220ms and scoped exclusively to changing cells?
- [ ] Are empty states and error messages honest, explicit, and actionable?
