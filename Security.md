# Security.md

This is a local-only, mock-data, single-user app with no real money or backend, so the security surface is small. This document exists to show the risks were considered, not to imply the app needs enterprise-grade hardening.

## 1. Threat Model
- **No network calls, no auth, no real financial data** — the primary risks are data integrity (local DB corruption/inconsistency) and input validation, not confidentiality or remote attack surface.
- Single local user on their own device; the SQLite DB is app-sandboxed by the OS (standard iOS/Android app data isolation) — no additional encryption required for this assignment's scope, but worth naming as a limitation.

## 2. Data Integrity
- **Transactional writes**: order submission (wallet debit/credit + holding upsert + order insert) must be atomic. Use a single DB transaction so a crash mid-write cannot leave the wallet debited without a corresponding holding update, or vice versa.
- **Single source of truth for prices**: all screens read from one `MarketDataService` instance to prevent divergent/inconsistent price displays across surfaces (a correctness issue, not a security one, but relevant to "no stale ticks shown for the wrong row" scenario).
- **Idempotent restarts**: app must be safe to kill at any point without corrupting the DB — no partial writes left uncommitted (Drift/sqflite transactions provide this if used correctly).

## 3. Input Validation
- Quantity: must be a positive integer; reject fractional, zero, negative, non-numeric, and overflow input at the form layer before it ever reaches order logic.
- Order value / balance comparisons done in integer minor-units or `Decimal` — never compare raw `double` currency values (floating-point equality/inequality bugs are a correctness *and* a trust issue in a financial-feeling app).
- Defensive checks duplicated at the domain layer (`OrderValidator`), not just the UI layer, so business rules hold even if a future screen calls the validator directly without going through the current form widget.

## 4. Local Storage
- No secrets, tokens, or credentials exist in this app (no login), so there is nothing to store securely in that sense.
- Wallet balance and order history are plain local app data — acceptable for a simulator; if this were ever extended toward real functionality, this section should be revisited to add encryption-at-rest and remote sync auth.

## 5. Dependency Hygiene
- Keep third-party packages to the minimum needed (state mgmt, DB, maybe `go_router`); avoid unmaintained or unnecessary packages to reduce supply-chain surface, even though the app is offline.
- Pin dependency versions in `pubspec.yaml`/`pubspec.lock` and commit the lockfile so the evaluator's build is reproducible.

## 6. Explicitly Out of Scope (state this in README too)
- Authentication/authorization (single implicit user).
- Network security (no network calls exist).
- Encryption at rest (no sensitive real-world data).
- Rate limiting / abuse prevention (no server, no multi-tenant concerns).

## 7. Recommendations if This Were Ever Productionized
(Not required for the assignment, but worth one sentence in the README to show awareness.)
- Real backend with authenticated, rate-limited market-data and order APIs.
- Server-side order validation (never trust client-computed order value).
- Encrypted local cache, biometric app-lock for financial data.
