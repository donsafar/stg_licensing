# RevenueCat (`purchases_flutter`) for the STG Portfolio

**Audience:** STG Flutter portfolio developers  
**Package:** `D:\0-SoftwareDevelopment\flutter\packages\licensing` (`stg_licensing`)  
**Status:** Planning guide — instructions only, no implementation  
**Last updated:** 2026-07-07

This document describes how to implement [RevenueCat](https://www.revenuecat.com/) via the [`purchases_flutter`](https://pub.dev/packages/purchases_flutter) SDK in a **centralized** way so all portfolio apps share one licensing package.

---

## Table of contents

1. [Scope and platform reality](#1-scope-and-platform-reality-read-this-first)
2. [RevenueCat vs licensing](#2-revenuecat-vs-licensing)
3. [Architectural goal](#3-architectural-goal)
4. [RevenueCat dashboard setup](#4-revenuecat-dashboard-setup-one-time-portfolio-wide)
5. [Critical change to existing `stg_licensing` behavior](#5-critical-change-to-existing-stg_licensing-behavior)
6. [Proposed package layout](#6-proposed-package-layout-in-packageslicensing)
7. [Entitlement resolution order](#7-entitlement-resolution-order-merge-logic)
8. [Riverpod integration](#8-riverpod-integration-extends-what-you-have)
9. [Identity and cross-device access](#9-identity-and-cross-device-access)
10. [UI integration](#10-ui-integration-minimal-app-specific-work)
11. [Per-app wiring checklist](#11-per-app-wiring-checklist-each-portfolio-app)
12. [Dependencies](#12-dependencies-to-add-when-you-implement)
13. [Store console checklist](#13-store-console-checklist-per-app-per-platform)
14. [Testing plan](#14-testing-plan)
15. [Suggested implementation phases](#15-suggested-implementation-phases)
16. [What to keep vs retire](#16-what-to-keep-vs-retire)
17. [Related documentation](#17-related-documentation-to-add-in-repo)
18. [Key decision: per-app vs bundle](#18-decision-you-should-make-before-coding)

---

## 1. Scope and platform reality (read this first)

The STG portfolio spans **8 apps** (`StgPortfolioAppId`) and multiple platforms. RevenueCat does **not** change that mix:

| Platform | RevenueCat support | Recommended STG approach |
|----------|-------------------|---------------------------|
| **iOS** | Native (`StoreKit`) | RevenueCat |
| **Android** | Native (`Play Billing`) | RevenueCat |
| **macOS** | Native | RevenueCat |
| **Flutter Web** | Web Billing (Stripe) | RevenueCat Web |
| **Windows desktop** (sideload `.exe`) | **Not supported** | Keep current local trial + license key, or “Subscribe on web” + account restore |
| **Linux** | **Not supported** | Same as Windows |

So `stg_licensing` should become a **unified licensing facade**, not “RevenueCat only.” RevenueCat is the **store billing backend** on supported platforms; Windows/Linux keep the existing prefs-based path (and optional web purchase + restore).

The existing `stg_health/docs/app_store_subscription_guide.md` describes raw `in_app_purchase`. With RevenueCat, you **replace direct store SDK usage** in app code — RevenueCat still talks to Apple/Google under the hood.

---

## 2. RevenueCat vs licensing

This distinction governs the whole design. **Do not treat RevenueCat as a replacement for `stg_licensing`.**

### One-liner

> **RevenueCat handles store billing and reports what the user bought; `stg_licensing` decides whether the app is in trial, licensed, or locked.**

### Responsibility split

| Layer | Responsibility |
|-------|----------------|
| **RevenueCat** | Purchase flow, receipt validation, renewal/cancel tracking, subscription **entitlement status** from App Store / Play / Web |
| **`stg_licensing`** | Trial rules, lockout, banner, router redirects, license keys (desktop), merge logic, feature gating |

RevenueCat answers: *“Does this user have an active Standard or Premium subscription?”*

`stg_licensing` answers: *“What should the app do — show the banner, allow access, lock the app, show the paywall?”*

### Data flow

```
RevenueCat (iOS / Android / macOS / Web)  ──►  stg_licensing  ──►  app behavior
     billing truth                               licensing control

Local prefs / license key (Windows desktop) ──►  stg_licensing  ──►  app behavior
```

RevenueCat **entitlements** are an **input** to `stg_licensing`, not the controller. App code should read `stgLicensingProvider` (or helpers built on it), not call RevenueCat directly for gating decisions.

### What RevenueCat does not do in this portfolio

- Windows desktop trial enforcement
- Master key / license key unlock
- Countdown banner formatting and blink rules
- Router lockout to `/trial-expired`
- Per-feature gates in app modules
- Portfolio pricing display (`stg_portfolio_pricing.dart`)

Those remain in **`stg_licensing`**.

### Terminology note

RevenueCat uses the word “entitlements” for paid access tiers. In STG docs, **licensing** means the full enforcement layer (`StgLicensingState`, phases, lockout, trials, keys). RevenueCat entitlements map **into** that layer via `StgBillingBackend`; they do not replace it.

---

## 3. Architectural goal

Today, entitlement flows like this:

```
SharedPreferences → readStgLicensingState() → StgLicensingProvider → banner / router lockout
```

Target flow:

```
┌─────────────────────────────────────────────────────────────┐
│                    stg_licensing (package)                   │
│                                                              │
│  StgBillingBackend (interface)                               │
│    ├─ RevenueCatBackend     (iOS / Android / macOS / Web)   │
│    └─ LocalLicensingBackend (Windows / Linux / QA / offline) │
│                                                              │
│  readStgLicensingState()  ← merges both sources              │
│  StgLicensingNotifier     ← purchase / restore / sync        │
│  StgLicenseExpiredPage    ← “Subscribe” + restore + key      │
└─────────────────────────────────────────────────────────────┘
         ▲                              ▲
         │ overrides                    │ minimal wiring
   stg_health, stg_checklist, ...   (app id, prefs, API keys)
```

**Rule:** Apps never import `purchases_flutter` directly. They only override providers and call `stg_licensing` APIs.

### Existing types to build on

| File | Role |
|------|------|
| `lib/src/stg_portfolio_app_id.dart` | `StgPortfolioAppId`, `StgPlanTier` |
| `lib/src/stg_portfolio_pricing.dart` | Display prices and trial days (workbook source of truth) |
| `lib/src/stg_licensing_state.dart` | `StgLicensingPhase`, `StgLicensingState` |
| `lib/src/stg_licensing_service.dart` | Prefs read/write, license key activation |
| `lib/src/stg_licensing_providers.dart` | `stgLicensingProvider`, Riverpod notifier |
| `lib/src/widgets/stg_license_expired_page.dart` | Lockout + license key entry |
| `lib/src/widgets/stg_licensing_status_banner.dart` | Countdown banner |

---

## 4. RevenueCat dashboard setup (one-time, portfolio-wide)

### 3.1 Create one RevenueCat project

Use a single project, e.g. **“Safar Technology Group”**, with **one RevenueCat “App” per store listing**:

| STG app | iOS bundle ID (example) | Android package | Notes |
|---------|-------------------------|-----------------|-------|
| STG Health | `com.safartechgroup.stg_health` | same | Ship first |
| STG Checklist | TBD | TBD | Add when ready |
| STG Task App | TBD | TBD | |
| STG DMS | TBD | TBD | |
| STG Projects | TBD | TBD | |
| STG Property Inventory | TBD | TBD | |
| STG Life | TBD | TBD | |
| STG File Catalog | TBD | TBD | |

You do **not** need 8 separate RevenueCat accounts.

### 3.2 Define entitlements (feature access)

Use **two entitlements per app** to match `StgPlanTier.standard` / `StgPlanTier.premium`:

```
stg_health_standard
stg_health_premium
```

Repeat pattern for each `StgPortfolioAppId`:

```
stg_{app}_standard
stg_{app}_premium
```

Premium should implicitly include Standard features in app code (check `premium` OR `standard` entitlement, or treat premium as superset in one helper).

### 3.3 Create store products (Apple + Google)

For each app and tier, create subscriptions in **App Store Connect** and **Google Play Console** first, then attach them in RevenueCat.

**Naming convention (recommended):**

```
stg_health_standard_yearly
stg_health_premium_yearly
```

Match pricing in `stg_portfolio_pricing.dart`. Display strings stay in that file; **store SKU IDs** go in a new catalog file (see §6).

**Trials:** Configure free trials as **introductory offers** in Apple/Google (7 or 14 days per app). RevenueCat will report `periodType == trial` in `CustomerInfo` — you can stop relying on local `trial_started_at_ms` on mobile once store billing is live.

### 3.4 Create Offerings

Per app, create an Offering, e.g. `stg_health_default`, with Packages:

| Package identifier | Maps to product | Entitlement |
|--------------------|-----------------|-------------|
| `$rc_annual` or `standard_annual` | `stg_health_standard_yearly` | `stg_health_standard` |
| `premium_annual` | `stg_health_premium_yearly` | `stg_health_premium` |

Use **consistent package identifiers** across apps so shared UI code can say “buy `premium_annual`” everywhere.

### 3.5 Web (optional, for Hostinger Flutter web)

Enable **RevenueCat Web Billing** + Stripe in the dashboard. You get a separate **Web API key**. Useful for users who subscribed on the web and open a desktop app that can’t bill natively.

### 3.6 API keys per platform

From RevenueCat → Project → API keys, collect:

- iOS public key
- Android public key
- Web public key (if used)

**Never commit keys.** Pass via `--dart-define` (same pattern as `STG_TRIAL_BUILD`).

Suggested dart-defines:

```
STG_REVENUECAT_IOS_KEY=appl_...
STG_REVENUECAT_ANDROID_KEY=goog_...
STG_REVENUECAT_WEB_KEY=rcb_...
```

---

## 5. Critical change to existing `stg_licensing` behavior

Today, in `StgLicensingNotifier`:

```dart
if (!stgTrialBuild) {
  return const StgLicensingState.notEnforced();
}
```

That means **release mobile builds without `STG_TRIAL_BUILD` skip all licensing**. Before shipping RevenueCat:

1. Add a new compile-time flag, e.g. `STG_LICENSING_ENFORCED` (default `false` for dev desktop, `true` for store CI builds).
2. Enforcement logic becomes: **enforced if** `stgLicensingEnforced || stgTrialBuild`.
3. On enforced store builds, **RevenueCat is the source of truth** for active subscriptions; local prefs are fallback/cache only.

Without this, RevenueCat can be integrated but will never gate production App Store / Play builds.

### Build flavor matrix (recommended)

| Build | `STG_TRIAL_BUILD` | `STG_LICENSING_ENFORCED` | Billing source |
|-------|-------------------|--------------------------|----------------|
| Dev desktop | `false` | `false` | Not enforced |
| Trial QA desktop | `true` | `false` | Local prefs |
| App Store / Play release | `false` | `true` | RevenueCat |
| Internal mobile QA | `true` | `true` | RC + short local trial override |

---

## 6. Proposed package layout (in `packages/licensing`)

Add these files (names are suggestions):

```
lib/
  src/
    billing/
      stg_billing_backend.dart          # abstract interface
      stg_billing_snapshot.dart         # normalized tier + expiry from any backend
      stg_billing_catalog.dart          # SKU / entitlement IDs per StgPortfolioAppId
      stg_revenuecat_config.dart        # API keys from dart-define
      stg_revenuecat_backend.dart       # Purchases.configure, purchase, restore
      stg_revenuecat_mapper.dart        # CustomerInfo → StgPlanTier + expiresAt
      stg_local_billing_backend.dart    # existing prefs + license key logic
      stg_billing_platform.dart         # isRevenueCatAvailable for this runtime
    stg_licensing_service.dart          # merge RC snapshot + local state
    stg_licensing_providers.dart        # add purchase/restore/sync methods
    widgets/
      stg_paywall_section.dart          # optional: embedded in expired page
```

Export new public APIs from `lib/stg_licensing.dart`.

### 5.1 `stg_billing_catalog.dart` (alongside pricing)

Keep **prices** in `stg_portfolio_pricing.dart` (marketing/UI).

Add **store identifiers** in a sibling catalog:

```dart
class StgBillingCatalog {
  static StgAppBillingSkus forApp(StgPortfolioAppId id) => ...
}

class StgAppBillingSkus {
  final String standardYearlyProductId;
  final String premiumYearlyProductId;
  final String standardEntitlementId;
  final String premiumEntitlementId;
  final String defaultOfferingId;
}
```

Single place to update when you add Checklist, DMS, etc.

### 5.2 `StgBillingBackend` interface

Minimum methods:

| Method | Purpose |
|--------|---------|
| `Future<void> configure(appId, userId?)` | Init SDK / no-op on Windows |
| `Future<StgBillingSnapshot?> getSnapshot()` | Current tier + expiry |
| `Stream<StgBillingSnapshot> watch()` | Customer info updates |
| `Future<StgPurchaseResult> purchasePackage(packageId)` | Buy Standard/Premium |
| `Future<void> restorePurchases()` | Required by Apple; “I already subscribed” |
| `Future<void> logIn(String appUserId)` | Tie RC customer to STG login |
| `Future<void> logOut()` | On STG logout (see §9) |

`StgBillingSnapshot` should map cleanly to existing `StgLicensingState` fields: `activeTier`, `expiresAt`, `phase`.

### 5.3 Windows-safe plugin inclusion

`purchases_flutter` may not compile cleanly on all desktop targets. Use one of:

**Option A (recommended):** Conditional exports in the package — stub backend on unsupported platforms, real backend only when `Platform.isIOS || Platform.isAndroid || Platform.isMacOS || kIsWeb`.

**Option B:** Split `stg_licensing_billing` into a second path package that only mobile/web apps depend on; Windows apps depend on `stg_licensing` core only.

Option A keeps “one package” as requested, with conditional-import care.

---

## 7. Entitlement resolution order (merge logic)

Implement `readStgLicensingState` (or a new async `resolveStgLicensingState`) with explicit priority:

```
1. RevenueCat active entitlement (if platform supports billing AND SDK configured)
      → licensedActive, tier from entitlement, expiry from CustomerInfo
2. Else local license key activation (prefs: license_tier_index / expires_at)
      → keep for desktop sideload + master key QA
3. Else local trial clock (prefs: trial_started_at_ms)
      → desktop QA + offline; optional on mobile until store trial takes over
4. Else trialPending / locked
```

**Premium beats Standard.** Expired RC subscription → `locked` → existing `StgLicenseExpiredPage`.

Persist a **cache** in SharedPreferences after each successful RC fetch (tier + expiry) for offline banner display — but treat cache as stale; revalidate on launch and on `CustomerInfo` listener.

### Prefs keys (existing, per app prefix)

| Key | Purpose |
|-----|---------|
| `{prefix}_trial_started_at_ms` | Local trial start |
| `{prefix}_license_tier_index` | Activated tier (desktop / key) |
| `{prefix}_license_expires_at_ms` | License expiry |
| `{prefix}_selected_plan_index` | UI plan selection |

Optional new cache keys after RC integration:

| Key | Purpose |
|-----|---------|
| `{prefix}_rc_tier_index` | Last known RC tier |
| `{prefix}_rc_expires_at_ms` | Last known RC expiry |
| `{prefix}_rc_synced_at_ms` | Last successful RC sync |

---

## 8. Riverpod integration (extends what you have)

### 7.1 New providers

| Provider | Role |
|----------|------|
| `stgBillingBackendProvider` | `RevenueCatBackend` or `LocalBillingBackend` by platform |
| `stgRevenueCatApiKeyProvider` | Host app supplies platform key via override |
| `stgBillingUserIdProvider` | Optional: STG username / Firebase UID for `Purchases.logIn` |

### 7.2 Extend `StgLicensingNotifier`

Add:

- `Future<void> syncFromStore()` — refresh `CustomerInfo`, update state
- `Future<bool> purchase(StgPlanTier tier)` — load Offering, pick package, call `purchasePackage`
- `Future<void> restorePurchases()`
- Subscribe to `Purchases.addCustomerInfoUpdateListener` in `build()` when RC is active

Keep existing `activateLicenseKey()` and `resetTrial()` for desktop/QA.

### 7.3 Bootstrap sequence (each app)

In `health_bootstrap.dart` (and equivalents):

```
1. Load SharedPreferences
2. If RevenueCat available:
     await billing.configure(appId, userId: session.username)
     await billing.syncFromStore()
3. Else:
     await ensureStgLicensingTrialStarted(prefs, appId)
4. Start stgLicensingProvider
```

Order matters: configure RC **before** first `readStgLicensingState` on mobile.

### 7.4 Example host app overrides (stg_health)

```dart
final stgHealthLicensingOverrides = [
  stgLicensingAppIdProvider.overrideWithValue(StgPortfolioAppId.health),
  stgLicensingPrefsProvider.overrideWith(
    (ref) => ref.watch(sharedPreferencesProvider),
  ),
  stgRevenueCatApiKeyProvider.overrideWith((ref) {
    // Return platform-appropriate key from dart-define
  }),
];
```

---

## 9. Identity and cross-device access

When user logs in (e.g. `donsafar49`):

```dart
await Purchases.logIn('stg_health:donsafar49');
// or plain username if globally unique across portfolio
```

Use a **stable, non-PII** app user id if possible. Prefix with app id if usernames could collide across products.

On logout:

- RevenueCat `logOut()` creates a new anonymous user — only call if you want purchases unlinked from session.
- Often better: **stay logged in to RC** with same anonymous→identified user and only clear STG session UI.

Document the chosen policy in the architecture doc.

---

## 10. UI integration (minimal app-specific work)

### 9.1 `StgLicenseExpiredPage`

Extend (in the package) with:

- **Subscribe** buttons → `notifier.purchase(standard|premium)`
- **Restore purchases** → `notifier.restorePurchases()`
- **Enter license key** → keep existing (desktop)
- **Subscribe on web** link (Windows only) → Hostinger checkout URL with return deep link

Prices still from `StgPortfolioPricing.forApp(appId)`.

### 9.2 Optional: RevenueCat Paywalls (`purchases_ui_flutter`)

RevenueCat can host paywall layout remotely.

| Pros | Cons |
|------|------|
| Change pricing UI without app release | Less control over STG branding |
| A/B testing built in | Extra dependency |

**Recommendation:** Start with existing `StgLicenseExpiredPage` + programmatic Offering fetch; add `purchases_ui_flutter` later if you want remote paywalls.

### 9.3 Banner

`StgLicensingStatusBanner` already formats countdown from `StgLicensingState`. Once RC provides `expiresAt`, banner works unchanged for licensed users.

Banner rules (already implemented):

- **>1 day:** show days + hours (no minutes)
- **≤1 day:** show minutes (blinking)
- **Zero:** `"{Tier} License Expired"`

---

## 11. Per-app wiring checklist (each portfolio app)

For `stg_health` (template for all apps):

1. **`pubspec.yaml`** — already depends on `stg_licensing`; no `purchases_flutter` in the app if centralized in package.
2. **`lib/providers/stg_licensing_config.dart`** — add overrides:
   - `stgLicensingAppIdProvider` (already done)
   - `stgRevenueCatApiKeyProvider` (read dart-define per platform)
3. **`main.dart`** — keep licensing overrides in `ProviderScope`.
4. **Bootstrap** — call billing configure/sync (§8.3).
5. **Router** — no change if still keyed off `stgLicensingProvider.isLocked`.
6. **CI build flavors:**
   - Desktop trial QA: `STG_TRIAL_BUILD=true` (unchanged)
   - Play/App Store release: `STG_LICENSING_ENFORCED=true` + RC keys
7. **Store listings** — subscriptions live, testers added, RevenueCat sandbox configured.

Repeat for each app, changing only `StgPortfolioAppId` and API keys.

### Portfolio app IDs

| `StgPortfolioAppId` | Prefs prefix |
|---------------------|--------------|
| `health` | `stg_health` |
| `checklist` | `stg_checklist` |
| `taskapp` | `stg_taskapp` |
| `dms` | `stg_dms` |
| `project` | `stg_project` |
| `propertyInventory` | `stg_property_inventory` |
| `life` | `stg_life` |
| `fileCatalog` | `stg_file_catalog` |

---

## 12. Dependencies to add (when you implement)

In `packages/licensing/pubspec.yaml`:

```yaml
dependencies:
  purchases_flutter: ^9.x   # check latest compatible with your Flutter SDK
  # optional later:
  # purchases_ui_flutter: ^9.x
```

Do **not** add `in_app_purchase` if you commit to RevenueCat — avoid duplicate purchase streams.

---

## 13. Store console checklist (per app, per platform)

### Apple (App Store Connect)

- [ ] Paid Apps Agreement, banking, tax
- [ ] Subscription group created
- [ ] Products: `stg_health_standard_yearly`, `stg_health_premium_yearly`
- [ ] Introductory free trial (14 days) on products
- [ ] Sandbox tester accounts
- [ ] Xcode: In-App Purchase capability

### Google Play

- [ ] Merchant account linked
- [ ] Subscriptions with same product IDs
- [ ] Base plan + free trial offer
- [ ] License testers added
- [ ] App signed with release key (billing won’t work on wrong signature)

### RevenueCat

- [ ] Apps linked (App Store Connect API key / Play service account JSON)
- [ ] Products imported and attached to entitlements
- [ ] Offering set as **Current**
- [ ] Entitlement identifiers match `stg_billing_catalog.dart`

---

## 14. Testing plan

| Scenario | How to test |
|----------|-------------|
| New install, mobile | Sandbox purchase → Premium active → banner shows licensed countdown |
| Store free trial | Subscribe with trial → `periodType` trial → full access |
| Trial expiry | Sandbox accelerated time (Apple) or QA short trial build |
| Restore | Delete app, reinstall, Restore → entitlements return |
| Login link | `Purchases.logIn` → same entitlements on second device |
| Windows desktop | No RC; local 5-min trial build; license key unlock |
| Offline mobile | Cached entitlement; grace behavior per store rules |
| Master key QA | Still works on desktop QA; disable or gate in store builds |

Enable debug logging during development:

```dart
await Purchases.setLogLevel(LogLevel.debug);
```

Use RevenueCat dashboard **Customer History** to verify events.

### Desktop trial QA (unchanged)

```powershell
.\tool\build_trial_desktop.ps1 -TrialMinutes 5
```

Prefs location on Windows:

```
%APPDATA%\com.safartechgroup\stg_health\shared_preferences.json
```

---

## 15. Suggested implementation phases

### Phase 0 — Design (now)

- [ ] Confirm Windows stays on local/key licensing
- [ ] Pick product ID naming convention
- [ ] Add `STG_LICENSING_ENFORCED` semantics
- [ ] This document reviewed and approved

### Phase 1 — Package skeleton

- [ ] `StgBillingBackend` + stubs
- [ ] `stg_billing_catalog.dart` for Health only
- [ ] Unit tests for mapper (`CustomerInfo` → `StgLicensingState`) with fixtures

### Phase 2 — STG Health mobile only

- [ ] RevenueCat project + Health products live in sandbox
- [ ] Configure/sync in bootstrap
- [ ] Purchase + restore from expired page
- [ ] Ship internal TestFlight / Play internal testing

### Phase 3 — Roll out portfolio

- [ ] Clone catalog entries for other `StgPortfolioAppId` values
- [ ] Per-app store products and offerings

### Phase 4 — Web + desktop bridge

- [ ] Web Billing on Hostinger deploy
- [ ] Windows “Manage subscription on web” + login restore

### Phase 5 — Hardening

- [ ] Webhooks to backend (optional) for analytics/support
- [ ] Reduce tamper-sensitive local trial on mobile (rely on store)
- [ ] NTP/device fingerprint from `7_day_single_device_trial_architecture.md` (optional, separate from RC)

---

## 16. What to keep vs retire

| Keep | Retire or narrow over time |
|------|----------------------------|
| `StgPortfolioAppId`, `StgPlanTier`, pricing sheet | Raw `in_app_purchase` as primary path |
| `StgLicensingState`, banner, expired page, router lockout | Local trial as **primary** gate on iOS/Android |
| License key path for Windows/desktop QA | Master key in public store builds (remove or server-gate) |
| `build_trial_desktop.ps1` | Duplicated billing code in each app |
| Riverpod overrides pattern | `stgTrialBuild`-only enforcement for production |

---

## 17. Related documentation to add in-repo

When implementation begins, add or update:

| Document | Purpose |
|----------|---------|
| `docs/revenuecat_dashboard_setup.md` | Step-by-step dashboard clicks |
| `docs/revenuecat_per_app_checklist.md` | Copy-paste for each new app |
| `docs/7_day_single_device_trial_architecture.md` | Clarify: mobile trial → store; desktop trial → local |
| `stg_health/docs/app_store_subscription_guide.md` | Mark superseded by RevenueCat or rewrite |

---

## 18. Decision you should make before coding

**One subscription per app vs STG bundle?**

- **Per app** (matches current pricing sheet): separate products per app; user pays per app. Simpler.
- **Bundle**: one “STG Premium All Apps” entitlement shared across RevenueCat apps — requires custom entitlement logic and unified product.

Current `StgPortfolioPricing` is **per-app**; stick with per-app RevenueCat apps/entitlements unless you explicitly productize a bundle.

---

## Appendix A — RevenueCat SDK quick reference

Initialization (conceptual — implement in `stg_revenuecat_backend.dart`):

```dart
final configuration = PurchasesConfiguration(apiKey);
if (userId != null) {
  await Purchases.logIn(userId);
}
await Purchases.configure(configuration);
```

Purchase flow:

```dart
final offerings = await Purchases.getOfferings();
final offering = offerings.current;
final package = offering?.availablePackages.firstWhere(
  (p) => p.identifier == 'premium_annual',
);
if (package != null) {
  await Purchases.purchasePackage(package);
}
```

Listen for updates:

```dart
Purchases.addCustomerInfoUpdateListener((customerInfo) {
  // Map to StgBillingSnapshot and refresh provider
});
```

Restore:

```dart
await Purchases.restorePurchases();
```

---

## Appendix B — Windows desktop workaround

Since RevenueCat does not support native Windows IAP today:

1. **Local trial** — existing `STG_TRIAL_BUILD` + prefs (current approach).
2. **License key** — manual unlock for sideload customers.
3. **Web purchase** — user subscribes on Hostinger Flutter web via RevenueCat Web Billing; desktop app calls `Purchases.logIn` + `restorePurchases` or `getCustomerInfo` if you add a thin web-sync path.
4. **Microsoft Store** (future) — would require a separate integration outside RevenueCat unless RC adds Windows support.

---

## Appendix C — File location

This guide lives at:

```
D:\0-SoftwareDevelopment\flutter\packages\licensing\docs\revenuecat_portfolio_implementation_guide.md
```

Shared licensing package:

```
D:\0-SoftwareDevelopment\flutter\packages\licensing\
```

Pilot app:

```
D:\0-SoftwareDevelopment\flutter\stg_health\
```
