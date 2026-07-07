# STG Health - pricing structure analysis and recommendation

**Date:** 2026-06-07 
**Audience:** Safar Technology Group product / commercial planning 
**Scope:** Recommended retail pricing for `stg_health` as the first app in a unified STG pricing study. 
**Status:** Strategic recommendation - not implemented in code or store listings.

---

## Executive recommendation

**Position STG Health as a privacy-first personal health journal with optional household/clinic administration - not as a MyFitnessPal clone.**

Recommended **three-tier** structure aligned with the STG product family naming (Trial / Standard / Premium) but with **health-market-adjusted price points**:

| Tier | Monthly | Annual | Primary buyer |
|------|---------|--------|---------------|
| **Trial** | $0 | $0 | New install - **10-day full-feature trial**, then read-only or export-only until upgrade |
| **Standard** | **$59.99** | Individual logging weight, food, exercise; basic reports |
| **Premium**  |  **$99.99** | Power users, families, coaches - PDF reports, multi-user admin, advanced food tools |

**Why these numbers:**

- **Annual Standard ($59.99)** sits between **Lose It! Premium ($39.99/yr)** and **Cronometer Gold (~$59.88/yr)** - appropriate for a smaller-brand app with strong offline/privacy positioning but without MFP-scale database or barcode ecosystem.
- **Annual Premium ($99.99)** matches the **STG Checklist / STG DMS Standard annual anchor ($99/yr)** and undercuts **MyFitnessPal Premium ($79.99/yr)** on monthly equivalent while staying below MFP Premium+ ($99.99/yr) - credible for "clinical-style reports + household admin" differentiation.
- **Monthly prices** use ~15-17% premium over annual amortization (common in nutrition apps) to nudge annual commits without punishing monthly buyers.

**Optional add-on (later):** **Household / Practice pack** - +$49/yr for up to **6 managed loggers** under one admin (see section 5).

---

## 1. What STG Health actually is (pricing inputs)

Findings from the `stg_health` codebase and docs (no in-app monetization exists today):

### Core value delivered today

| Capability | Notes |
|------------|--------|
| Food logging | Meal categories, branded + custom foods, USDA-backed local catalog, FTS search |
| Recipe intelligence | Natural-language home-cooked recipe -> ingredient nutrition estimate |
| Packaged food lookup | URL-based product resolution via self-hosted WordPress API |
| Weight + exercise | Weekly weigh-in friendly reports; exercise catalog + calorie burn |
| Profile + goals | BMI, daily calorie target, American/Metric units |
| Reports | Nine report types; charts; **PDF/Markdown export on desktop/mobile IO** |
| Multi-user + admin | Admin manages users; filter logs/reports across users |
| Local-first SQLite | Data under `Documents\stg_health\`; backup/restore |
| Web | **Read-only** hydrated demo via WordPress - not a write SaaS |

### Not yet shipped (affects pricing promise)

- Vitals UI (BP/pulse schema only)
- Barcode scanning, meal photo AI, social/community
- Cloud sync as a consumer subscription (sync is maintainer-driven WP import today)

### Distribution readiness

- Google Play (`.aab`), Microsoft Store (MSIX), sideload/tester zips (`installer/STORE_DISTRIBUTION.md`)
- Publisher: Safar Technology Group
- STG-wide trial guidance: 10-day store + server entitlement model (`docs/2026-06-04_STG_app_store_trial_and_licensing.md`)

**Pricing implication:** You can sell **offline-capable desktop/mobile** as the product. Web is a **viewer/demo**, not the paid surface - unless you later enable authenticated write-back on WordPress.

---

## 2. Competitive landscape (consumer nutrition apps, 2026)

Public pricing from major calorie/weight trackers (verify before store submission; prices change):

| App | Free tier | Paid (typical US) | What buyers pay for |
|-----|-----------|-------------------|---------------------|
| **FatSecret** | Generous free | Low premium optional | Budget logging |
| **Lose It!** | Yes | **~$39.99/year** | Affordable premium, photo/barcode |
| **Cronometer Gold** | Yes (ads) | **~$59.88/year** ($4.99/mo annual) | Micronutrients, verified data, history |
| **MyFitnessPal Premium** | Limited free | **$79.99/year** or $19.99/mo | Huge DB, barcode, meal scan, macros |
| **MyFitnessPal Premium+** | - | **$99.99/year** or $24.99/mo | Meal planner add-on |
| **MacroFactor** | 7-day trial only | **~$71.99/year** | Adaptive coaching algorithm |
| **Noom** | Limited | **~$200+/year** | Behavior coaching |

**Market takeaway for STG Health:**

- **$40-60/year** is the "serious but not MFP" annual band for individuals.
- **$80-100/year** requires **clear premium differentiation** (reports, privacy, multi-user, or pro/clinical tooling).
- **$20+/month** monthly list prices are hard to justify without barcode, AI photo logging, or coaching - STG Health should **anchor on annual** in marketing copy.

**STG Health does not compete on:** database size (20M+ foods), barcode/meal scan, social feeds, or live coaching.

**STG Health can compete on:** local data ownership, no ads, recipe-from-text, printable clinical-style reports, admin-managed family logging, and optional self-hosted web mirror.

---

## 3. STG portfolio consistency

Existing **mock/display baselines** in sister apps (not store-enforced):

| App | Standard | Premium |
|-----|----------|---------|
| `stg_checklist` | **$59.99** yr|  **$99.99** yr|
| `stg_dms` |  **$59.99** yr| **$99.99** yr|
| `stg_focus` |  **$59.99** yr| **$99.99** yr|


**Recommendation for STG Health:**

- Use **$99.99/year Premium** to align with the **$99.99 STG annual standard** family price (round number, cross-app bundle potential).
- Price **Standard lower than checklist** ($59.99 vs $99.99) because:
 - Consumer nutrition apps cluster lower than productivity/DMS tools.
 - STG Health must win individuals before upselling household admin.
- Keep tier **names** Trial / Standard / Premium across STG for bundle messaging ("STG Premium bundle - all apps").

---

## 4. Recommended tiers - detail

### Trial (14 days)

| Element | Recommendation |
|---------|----------------|
| Price | $0 |
| Duration | **14 days** full access (slightly more generous than STG 10-day doc - nutrition apps often use 7-14 days; MFP offers 7-day Premium trial) |
| Scope | All features of Premium |
| After trial | **Soft landing:** read-only access to existing logs + one PDF export; new logs and reports blocked until subscribe |
| Abuse control | Store account + STG entitlement server per `2026-06-04_STG_app_store_trial_and_licensing.md` |

**Why 14 days:** Weight and calorie habits need **~2 weeks** of logging before weekly/monthly reports feel valuable.

---

### Standard - $59.99/year**

**Target:** Individual adult tracking weight, food, and exercise for personal goals.

| Include | Exclude (Premium upsell) |
|---------|--------------------------|
| Unlimited food/weight/exercise logging (single user) | Multi-user admin & cross-user reports |
| Local USDA + custom food search (bundled catalog) | PDF/Markdown report export |
| Profile, BMI, calorie goal | Packaged food URL lookup (server cost) |
| In-app report **preview** (charts on screen) | Recipe natural-language parser |
| Backup/restore (local) | Priority support |
| American + Metric units | Web sync / read-only web mirror setup |

**Rationale:** $59.99/yr is **~$5/mo** - psychologically under checklist/DMS, competitive with Cronometer Gold, premium over Lose It! justified by offline + no ads + richer reports preview.

---

### Premium - $99.99/year**

**Target:** Users who want **exportable reports for clinicians**, home cooks, and **households** where one admin manages multiple loggers.

| Everything in Standard, plus |
|------------------------------|
| **PDF + Markdown report export** (desktop/mobile) |
| **Recipe parser** -> save as custom food |
| **Packaged food URL lookup** (API-backed) |
| **Multi-user admin** - up to **3** additional loggers (4 total including admin) |
| **Reports filtered by user / all users** |
| **Health dashboard** printable snapshot |
| Optional: USDA live API toggle (if you want to gate API quota) |

**Rationale:** $99.99/yr matches STG family annual Standard/Premium anchor tier used elsewhere; feature set maps to "doctor visit packet + family" positioning in `docs/2026-05-29_health_report_recommendations.md`.

---

### Optional future tier: **Practice / Family+**

Only if you invest in admin UX and support:

| Price | **$199/year** |
| Users | Up to **6** managed loggers |
| Adds | Vitals logging (when shipped), scheduled email report export, branded PDF cover sheet, priority support |

Do **not** launch this on day one - adds support burden without RPM-grade compliance (HIPAA, CPT billing). STG Health is **not** an RPM platform today.

---

## 5. Alternative models considered (and why not primary)

### A. Match checklist exactly ($9.99 / $24.99 monthly)

**Pros:** Brand consistency, simple STG bundle. 
**Cons:** $119.88/year Standard is **above MyFitnessPal** without barcode/AI - hard sell for first-time health app buyers.

### B. One-time purchase ($49.99-$79.99 lifetime)

**Pros:** Fits local-first, privacy audience; no subscription fatigue. 
**Cons:** No recurring revenue; store policies still expect ongoing updates; WordPress API costs unfunded. 
**Verdict:** Offer as **limited promotion** or **Microsoft Store lifetime SKU** later, not main model.

### C. Freemium forever (FatSecret-style)

**Pros:** Growth. 
**Cons:** Undermines report export and admin differentiation; STG apps historically use **trial -> paid** (`2026-06-04_STG_app_store_trial_and_licensing.md`). 
**Verdict:** Allow **permanent free** only for **single user, 30-day history, no export** if you need store funnel - otherwise trial-only is cleaner.

### D. B2B per-patient RPM pricing ($15-80/patient/month)

**Pros:** High ARPU. 
**Cons:** STG Health lacks device integration, HIPAA program, EHR, billing codes - would be misleading. 
**Verdict:** Revisit only with vitals UI, audit trail, and BAA-ready hosting - **different product**.

### E. Web SaaS subscription

**Pros:** Recurring revenue from browser users. 
**Cons:** Web is **read-only** today; enabling write + auth is substantial engineering. 
**Verdict:** Price **self-hosted WordPress sync** as a **Premium+** or **one-time setup fee** for clinics, not monthly web-only SaaS yet.

---

## 6. Suggested feature gates (implementation order)

When you add `PlanId` / entitlements (see `docs/2026-06-07_stg_tools_licensing_sources.md`):

| Priority | Gate | Tier |
|----------|------|------|
| P0 | Trial expiry -> block new logs | Trial |
| P1 | PDF/MD export | Premium |
| P2 | Multi-user admin + report filters | Premium |
| P3 | Recipe parser + URL packaged lookup | Premium |
| P4 | History beyond 90 days on reports | Standard = 90d, Premium = unlimited |
| P5 | Custom food count cap | Standard = 50, Premium = unlimited |

**Keep free of gates:** core logging, on-screen charts, local backup - users must trust the app before paywall.

---

## 7. Store listing and copy guidance

**Lead with:**

- "Your health data stays on your device."
- "Printable weight, calorie, and exercise reports for clinic visits."
- "No ads. No selling your food log."

**Avoid claiming:**

- "Largest food database" (MFP/Lose It scale)
- "HIPAA-compliant RPM" (not true today)
- "AI meal photo scan" (not shipped)

**Trial CTA:** "14-day full access - see your first weekly health summary before you subscribe."

**Annual nudge:** "Save 28% vs monthly" ($59.99 vs $83.88 Standard; $99.99 vs $155.88 Premium).

---

## 8. Revenue scenarios (illustrative)

Assumptions: 1,000 paying users after year 1, 70% annual / 30% monthly, 80% Standard / 20% Premium.

| Mix | Approx. ARPU/month | Annual revenue |
|-----|-------------------|----------------|
| Mostly Standard annual | ~$4.20 | ~$50,400 |
| Blended as above | ~$5.50 | ~$66,000 |
| 30% Premium uplift | ~$6.80 | ~$81,600 |

Numbers are **order-of-magnitude** only - actual conversion depends on store visibility, trial length, and feature gates.

**Bundle opportunity:** "STG Premium All-Access" at **$19.99/mo / $199/yr** across Health + Checklist + Taskapp could raise ARPU without raising per-app sticker shock.

---

## 9. Summary table - proposed STG Health pricing

| Tier |  Annual | Best for |
|------|---------|--------|----------|
| Trial | $0 (14 days) | - | Evaluation |
| Standard |$59.99 | Solo tracker |
| Premium  |$99.99 | Exports, recipes, family admin |
| Practice+ (future) | $19.99 | $199.00 | Larger households / light clinical use |

**Display labels** (for future Tools -> Licensing Control, matching STG convention):

```text
stgHealthTrialPlanPriceLabel = '$0'
stgHealthStandardPlanPriceLabel = '$59.99/year'
stgHealthPremiumPlanPriceLabel = '$99.99/year'
```

---

## 10. Sources and references

### STG internal

- `stg_health/docs/stg_health_user_guide.md` - feature inventory
- `stg_health/docs/2026-05-29_health_report_recommendations.md` - clinical/report positioning
- `stg_health/installer/STORE_DISTRIBUTION.md` - store channels
- `stg_baseapp/docs/2026-06-04_STG_app_store_trial_and_licensing.md` - trial / entitlement strategy
- `stg_baseapp/docs/2026-06-07_stg_tools_licensing_sources.md` - mock tier patterns in sister apps
- `stg_checklist/lib/core/config/app_config.dart` - STG checklist price baseline
- `stg_dms/lib/globals.dart` - STG DMS price baseline

### External market (accessed 2026-06-07; confirm before publish)

- [MyFitnessPal membership pricing](https://blog.myfitnesspal.com/myfitnesspal-membership-pricing-tiers/) - Premium $79.99/yr, Premium+ $99.99/yr
- [MyFitnessPal paywall analysis (2026)](https://thenutritionmagazine.com/articles/myfitnesspal-paywall-changes-explained/) - competitor price comparison
- [Calorie tracking app comparison (2026)](https://kcalm.app/blog/best-calorie-tracking-apps-comparison/) - Lose It, Cronometer, MacroFactor bands
- [Cronometer pricing guide (2026)](https://nutriscan.app/blog/posts/cronometer-pricing-2026-basic-vs-gold-vs-pro-b28e621201) - Gold ~$59.88/yr; Pro for professionals

---

## 11. Next steps (if you adopt this model)

1. Validate prices with 5-10 target users (solo tracker vs family admin).
2. Add `lib/core/config/app_config.dart` entitlements in `stg_health` (mirror checklist/taskapp).
3. Configure Play / Microsoft Store subscriptions to match SKUs.
4. Implement trial + export gate first (highest perceived value).
5. Revisit **Practice+** when vitals UI ships and you define HIPAA posture.

---

*Analysis prepared for STG commercial planning - 2026-06-07.*
