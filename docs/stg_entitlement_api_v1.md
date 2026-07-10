# STG Entitlement API v1 — Phase 2 spec (Apple & Google only)

**Status:** Draft for implementation alongside RevenueCat sandbox + `stg_health`  
**Platforms:** **Apple App Store** and **Google Play** only (via RevenueCat)  
**Scope:** One STG user identity, per-app annual Standard/Premium, offline-friendly cache  
**Out of scope v1:** Microsoft Store, web/Stripe checkout, emailed license keys, portfolio bundle SKU, admin UI (SQL/scripts OK)

---

## 1. Architecture

**RevenueCat** receives purchases from **App Store** and **Play Billing**, then sends webhooks to the **STG Entitlement API**. The API is the source of truth for `user × app × tier × expires_at`. Flutter apps authenticate with a **STG JWT**, call `GET /entitlements`, cache locally, and `stg_licensing` merges: **server entitlement → local 14-day trial → read-only**. Device seats are enforced at `POST /devices/register` (default **2** per user per app — e.g. iPhone + iPad).

```
App Store ──┐
            ├──► RevenueCat ──webhook──► Entitlement API ◄──JWT── Flutter app (iOS / Android)
Google Play ┘                                      │
                                                   ▼
                                            Postgres / Supabase
```

---

## 2. Identity

| Item | Rule |
|------|------|
| User id | UUID (`users.id`), stable across apps |
| App login | Email + password or magic link → STG JWT (`sub` = user id) |
| RevenueCat | `Purchases.logIn(stgUserId)` after STG login (same UUID string) |
| Webhook mapping | RC `app_user_id` = STG `users.id` |

---

## 3. Data model (minimal tables)

### `users`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `email` | text UNIQUE | |
| `created_at` | timestamptz | |

### `subscriptions` (audit / billing mirror)

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK → users | |
| `app_id` | text | e.g. `stg_health` |
| `provider` | text | `revenuecat` |
| `provider_ref` | text | RC subscription / transaction id |
| `store` | text | `app_store` \| `play_store` |
| `tier` | text | `standard` \| `premium` |
| `status` | text | `active` \| `canceled` \| `expired` |
| `current_period_end` | timestamptz | Renewal / lapse boundary |
| `updated_at` | timestamptz | |

### `entitlements` (what apps read)

| Column | Type | Notes |
|--------|------|-------|
| `user_id` | UUID FK | |
| `app_id` | text | |
| `tier` | text | `standard` \| `premium` |
| `expires_at` | timestamptz | UTC; `now < expires_at` ⇒ paid access |
| `source` | text | `revenuecat` \| `support_grant` |
| `updated_at` | timestamptz | |
| **PK** | | `(user_id, app_id)` |

### `devices` (seat limit)

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK | |
| `app_id` | text | |
| `device_hash` | text | SHA-256(platform fingerprint + salt) |
| `label` | text | Optional: `iPhone 15`, `Pixel 8` |
| `registered_at` | timestamptz | |
| `last_seen_at` | timestamptz | |
| **UNIQUE** | | `(user_id, app_id, device_hash)` |

**v1 seat policy:** `max_devices = 2` per `(user_id, app_id)`. Same `device_hash` on reinstall → **200**. New hash at limit → **409 DEVICE_LIMIT**.

---

## 4. REST API

Base: `https://api.safartechgroup.com/v1` (or Supabase Edge Functions).  
Authenticated routes: `Authorization: Bearer <stg_jwt>`.

### `GET /entitlements?app_id=stg_health`

**Response 200**

```json
{
  "app_id": "stg_health",
  "access": "licensed",
  "tier": "premium",
  "expires_at": "2027-07-10T12:00:00Z",
  "server_time": "2026-07-10T21:00:00Z",
  "cache_ttl_seconds": 86400
}
```

| `access` | Meaning |
|----------|---------|
| `licensed` | `expires_at` in future → full access (tier gates apply) |
| `none` | No active sub → local trial or read-only |

**Errors:** `401` invalid JWT.

---

### `POST /devices/register`

```json
{
  "app_id": "stg_health",
  "device_hash": "a1b2…",
  "label": "iPhone"
}
```

**201** created | **200** already registered | **409** seat limit.

---

### `POST /webhooks/revenuecat`

Verify RC signing secret. On `INITIAL_PURCHASE`, `RENEWAL`, `PRODUCT_CHANGE`, `CANCELLATION`, `EXPIRATION`:

1. Resolve `app_user_id` → `user_id`
2. Map RC entitlement id → `app_id` + `tier`; record `store` from event payload
3. Upsert `subscriptions` + `entitlements` (`expires_at` = RC expiration)

**Idempotent** on RC event id.

---

### `POST /support/grant` (internal, API key)

Manual grant: `{ "user_id", "app_id", "tier", "expires_at" }`. Not exposed to apps.

---

## 5. Store mapping (config)

| RC entitlement id | `app_id` | `tier` |
|-------------------|----------|--------|
| `stg_health_standard` | `stg_health` | `standard` |
| `stg_health_premium` | `stg_health` | `premium` |

| Store | Yearly product id pattern |
|-------|---------------------------|
| **Apple** | `{bundle_id}.standard.yearly`, `{bundle_id}.premium.yearly` |
| **Google** | Same id pattern in Play Console subscription products |

See `annual_subscriptions_deployment_guide.md` for console setup.

---

## 6. Client merge rules (`stg_licensing`)

**On launch (and after purchase / login):**

```
1. If STG JWT present AND network available:
     GET /entitlements?app_id=…
     POST /devices/register (once per install)
     Write cache (§7)

2. Merge into StgLicensingState:
     a. cached/server licensed AND now < expires_at → licensedActive
     b. local trial active (14d) → trialActive (Premium-equivalent gates)
     c. else → readOnly

3. RevenueCat: syncFromStore() on iOS/Android; webhook updates server.
   Logged-in users → server entitlement wins. RC CustomerInfo is fallback if API unreachable but RC cache valid.
```

Anonymous install → **local trial only** until STG login + in-app purchase.

---

## 7. Offline cache rules

| Key | Value |
|-----|-------|
| `{prefix}_entitlement_tier` | `standard` \| `premium` |
| `{prefix}_entitlement_expires_at_ms` | UTC ms |
| `{prefix}_entitlement_synced_at_ms` | Last successful GET |
| `{prefix}_entitlement_access` | `licensed` \| `none` |

| Condition | Behavior |
|-----------|----------|
| Offline + `licensed` + `now < expires_at` | Full write access |
| Offline + `expires_at` passed | Read-only |
| Online + sync success | Refresh cache |
| Online + sync fail + valid cache | Keep cache; retry next launch |
| Hard boundary | Always `expires_at`, not cache TTL |

**Restore purchases (Apple requirement):** online → RC `restorePurchases()` + `GET /entitlements`.

---

## 8. Phase 2 delivery checklist (Apple & Google)

| # | Task |
|---|------|
| 1 | Deploy Entitlement API + 4 tables (Supabase recommended) |
| 2 | STG auth (JWT) in `stg_health` login flow |
| 3 | **App Store Connect:** subscription group, yearly Standard + Premium SKUs, sandbox testers |
| 4 | **Google Play Console:** subscription products (same ids), license testers on internal track |
| 5 | **RevenueCat:** project, iOS + Android apps, entitlements, offerings, webhook URL + secret |
| 6 | `stg_licensing`: `StgEntitlementClient`, cache keys, merge in `readStgLicensingState` |
| 7 | `stg_licensing`: RevenueCat `configure`, `purchase`, `restorePurchases`, `logIn(stgUserId)` |
| 8 | `/subscribe`: Subscribe → RC purchase; Restore → RC + `GET /entitlements` |
| 9 | Tests: sandbox purchase (iOS + Android), restore on second device, offline until `expires_at`, expired read-only, trial before login, device seat 409 |

---

## 9. Explicit non-goals (v1)

- **Microsoft Store** / Windows desktop store billing  
- **Web checkout** (Stripe) and RevenueCat Web Billing  
- Emailed license keys / `activateLicenseKey` in production builds  
- Per-device keys without STG user account  
- Cross-app bundle entitlement (one SKU unlocks all apps)  
- Real-time socket sync (poll on launch + post-purchase is enough)

---

*Safar Technology Group — Entitlement API v1 (Apple & Google), companion to `revenuecat_portfolio_implementation_guide.md`.*
