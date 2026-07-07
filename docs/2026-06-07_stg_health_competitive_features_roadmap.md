# STG Health - competitive feature roadmap

**Date:** 2026-06-07 
**Audience:** Safar Technology Group product and engineering 
**Sources:** [2026-06-07_Health_and_Nutrition_Apps_Comparison.xlsx](2026-06-07_Health_and_Nutrition_Apps_Comparison.xlsx), [2026-06-07_stg_health_pricing_analysis.md](2026-06-07_stg_health_pricing_analysis.md), `stg_health` codebase audit 
**Goal:** Define what **STG Health** must add (or sharpen) to be **ultra competitive** with the ten apps in the comparison matrix - without abandoning its local-first, privacy-first positioning.

---

## Executive summary

STG Health **cannot** win by cloning MyFitnessPal's 14M-food database or Fitbit's wearable sleep stack. It **can** become ultra competitive by combining:

1. **Table-stakes logging** that users expect in 2026 (barcode, fast mobile logging, health-platform sync).
2. **Differentiated depth** it already owns (offline desktop, PDF clinical reports, recipe intelligence, household admin).
3. **Smart metabolism tooling** (MacroFactor-style trend smoothing and adaptive goals) without guilt-based coaching.
4. **Selective ecosystem integration** (Apple Health / Google Fit read-write for weight, steps, sleep duration) rather than building a full health hub.

**Top 10 features to reach "ultra competitive"** (ordered):

| Priority | Feature | Closes gap vs |
|----------|---------|---------------|
| P0 | Barcode scanner for packaged foods | MyFitnessPal, Lose It!, Lifesum, Fitbit |
| P0 | Apple Health + Google Fit sync (weight, steps, sleep duration, workouts) | Apple Health, Google Fit, Samsung Health, Fitbit, MFP |
| P0 | Water logging + daily hydration goal | MFP, Lose It!, Lifesum, Samsung Health, Fitbit |
| P1 | Photo / meal-scan assist for food logging | Lose It!, MFP Premium |
| P1 | Adaptive calorie goal (expenditure trend from weight + intake) | MacroFactor, Lose It! forecasting |
| P1 | Body measurements beyond weight (waist, body fat %, optional photos) | Cronometer, Lifesum, Lose It! |
| P1 | Vitals UI (BP, pulse, glucose optional) - schema exists | Cronometer, Samsung Health |
| P2 | Micronutrient display (extend USDA catalog fields) | Cronometer |
| P2 | Motivational progress UX (milestones, goal date, weight smoothing) | Lose It!, Lifesum |
| P2 | Full web write path or consumer cloud backup (optional sync) | MFP Web, Cronometer Web |

Everything else in the matrix (native sleep staging, SpO2, ECG, medication reminders) is **ecosystem-hub territory** - integrate via Health Connect / HealthKit, do not rebuild.

---

## Comparison baseline

Matrix apps (row order in spreadsheet):

| App | Primary moat |
|-----|----------------|
| MyFitnessPal | Food DB + barcode |
| Cronometer | Micronutrient accuracy + biometrics |
| Lose It! | Motivation + photo/barcode + forecasting |
| Apple Health | iOS data hub |
| Google Fit | Cross-device aggregate |
| Samsung Health | Samsung wearable biometrics |
| Fitbit | Sleep + wearable metrics |
| MacroFactor | Adaptive expenditure algorithm |
| Lifesum | Habit UI + diet plans + barcode |
| Sleep Cycle | Acoustic sleep analysis |
| **STG Health** | Local privacy + reports + admin + recipes |

---

## What STG Health already wins on (protect and market)

These are **not gaps** - double down in positioning and keep parity in quality:

| Strength | Spreadsheet column | Competitive note |
|----------|-------------------|------------------|
| **Desktop + Linux** native app | Platforms | None of the nutrition leaders ship Linux desktop; STG is unique for power users |
| **Offline SQLite** | Key advantage | Beats cloud-only MFP/Lose It for privacy and clinic-sensitive users |
| **PDF/Markdown report export** | Other metrics / Key advantage | Cronometer Pro is professional-tier; STG offers consumer-clinical reports today |
| **Multi-user household admin** | Key advantage | No matrix app offers admin-managed family logging in one DB |
| **Home-recipe nutrition parser** | Calorie tracking | Deeper than "recipe builder" alone - natural language -> ingredients |
| **USDA-backed local catalog** | Calorie tracking | Credible vs Cronometer on data quality for core macros (not yet 84 micros) |
| **Weekly weight report semantics** | Weight tracking | Good for weekly weigh-in users; needs smoothing + forecasting to match Lose It! |
| **No ads** | Pricing perception | Matches MacroFactor positioning |

---

## Gap analysis by matrix column

### 1. Platforms supported

| Competitor pattern | STG Health today | Gap | Ultra-competitive target |
|--------------------|------------------|-----|--------------------------|
| iOS, Android, **Web (full)** | iOS, Android, Win, macOS, Linux; **Web read-only** | Web cannot log or export | **Web:** read + write via authenticated sync, or clearly sell desktop/mobile only |
| watchOS / WearOS apps | None | No glance logging or complications | **Phase 2:** Apple Watch / Wear quick-add water, weight, last meal (via companion + Health sync) |
| Smart-scale Bluetooth | Google Fit, Fitbit, Samsung | No scale sync | **P2:** Import weight from Health Connect / HealthKit (covers most scales) |

**Minimum bar:** Mobile iOS + Android feature parity with desktop for logging (not admin-only on mobile).

---

### 2. Weight tracking

| Competitor capability | STG gap | Feature needed |
|----------------------|---------|----------------|
| Comprehensive history + charts | Partial - weekly aggregation strong; daily chart in reports | Daily weight sparkline on home; zoomable trend chart |
| Target goal setting | Profile calorie goal yes; weight goal less prominent | Explicit **target weight** + target date |
| Body fat %, lean mass, muscle | Not tracked | Optional body composition fields on weight log |
| Goal achievement date / forecasting | Missing | **Weight trend line** + estimated goal date (Lose It!-style) |
| Water fluctuation smoothing | Raw weigh-ins only | **Exponential smoothing** option (MacroFactor-style) for display and reports |
| Smart-scale sync | Missing | Health platform import |
| Progress photos | Lifesum | Optional photo attach to weight entry (local storage) |
| Milestone rewards | Lose It! | Lightweight milestones (5 lb, 10 lb) - no gamification overload |

**Ultra-competitive weight stack:** target weight + smoothed trend + forecast date + body fat optional + Health sync + clinical PDF (already have).

---

### 3. Calorie / nutrient tracking

| Competitor capability | STG gap | Feature needed |
|----------------------|---------|----------------|
| Massive verified DB (14M+) | Local USDA catalog smaller | Keep FTS + USDA; add **Open Food Facts** or periodic catalog updates; barcode bridges gap |
| **Barcode scanner** | **Missing** | **P0** - scan UPC -> food item (OFF or USDA branded) |
| Photo / meal scan | Missing | **P1** - camera -> estimate portion (on-device or API); start with barcode + search before full AI |
| Macro breakdown | Partial (calories; macros in catalog) | Show **protein / carb / fat** per day and per meal on home + reports |
| 84 micronutrients | Macros only | **P2** - surface key micros (fiber, sodium, vitamins) from USDA fields already in catalog |
| Voice logging | MFP Premium | **P3** - nice-to-have after barcode |
| Recipe builder | Have recipe parser | Improve UX: edit parsed ingredients, save template |
| Diet plans (Keto, etc.) | Missing | **P3** - preset macro templates, not full Lifesum meal plans |
| Packaged URL lookup | Have (server) | Keep as Premium; add offline fallback |

**Ultra-competitive food stack:** barcode + fast search + macros by meal + recipe parser + optional photo assist.

---

### 4. Sleep monitoring

| Competitor capability | STG gap | Feature needed |
|----------------------|---------|----------------|
| Native sleep staging | None | **Do not build** native staging |
| Sleep duration from Health | None | **P0** - read sleep duration from Apple Health / Health Connect; show in weekly summary report |
| Deep/REM stages | Fitbit, Cronometer | Display if present in Health export; no custom sensors |
| Sleep score / snoring | Samsung, Fitbit, Sleep Cycle | **Out of scope** unless partnering with wearable APIs |

**Ultra-competitive sleep stance:** **Integrate, don't invent** - one row in weekly report: average sleep hours (7-day) from Health sync. Enough to not look empty vs MFP "basic integration."

---

### 5. Other health metrics

| Competitor capability | STG gap | Feature needed |
|----------------------|---------|----------------|
| Water logging | Missing | **P0** - daily water ml/cups + goal |
| Exercise / step sync | Manual exercise log only | **P0** - import steps and workouts from Health; merge with manual exercise |
| Custom macro goals | Calorie goal only | **P1** - protein/carb/fat targets on profile |
| Fasting timer | Cronometer | **P3** - optional intermittent fasting window |
| Blood pressure, glucose, temperature | Schema for vitals; no UI | **P1** - ship **vitals log UI** (BP, pulse; glucose optional) |
| Heart rate / HRV / SpO2 | Fitbit, Samsung | Read from Health if available; display in vitals section |
| Medication reminders | Apple Health | **Out of scope** for v1 competitive parity |
| Energy balance report | **Have** | Keep; add to home dashboard |
| Habits checklist | Lifesum | **P3** - optional habit ticks (water, weigh-in, exercise) |

**Ultra-competitive metrics stack:** water + steps sync + vitals UI + macros + existing exercise/energy reports.

---

### 6. Pricing structure (perceived value)

Matrix competitors offer **robust free tiers** (MFP limited, Cronometer free, Lose It basic). STG proposed model is **trial -> paid** ([pricing analysis](2026-06-07_stg_health_pricing_analysis.md)).

To feel ultra competitive at **$59.99/yr Standard**:

| Must be in Standard | Premium upsell |
|-------------------|----------------|
| Barcode scanning | Photo meal scan |
| Health sync (weight, steps, sleep hours) | Multi-user admin + cross-user reports |
| Water + macro daily view | PDF export |
| On-screen report preview | Recipe parser + URL lookup |
| Unlimited logging | Unlimited history / advanced micros |

Without **barcode + Health sync** in Standard, users will compare STG unfavorably to **free** Cronometer and **$39.99/yr** Lose It!.

---

## Prioritized feature backlog

### P0 - Must ship for "credible competitor" (6-9 months)

| # | Feature | Acceptance criteria | Notes |
|---|---------|-------------------|-------|
| 1 | **Barcode food logging** | Scan UPC -> match catalog or OFF -> add to meal | `mobile_scanner` or ML Kit; extend `food_search_field` |
| 2 | **Apple Health integration** | Read/write weight, dietary energy, water, steps, sleep duration | `health` package; iOS/macOS |
| 3 | **Health Connect (Android)** | Same metrics as Apple Health | Google Health Connect API |
| 4 | **Water logging** | Daily total + quick-add on home/food | New log type or daily summary row |
| 5 | **Daily macro summary** | P/C/F rings or bars vs goals | Profile macro targets + aggregation |
| 6 | **Target weight + goal date** | Profile fields + progress % | Feeds forecasting |
| 7 | **Mobile logging parity** | All core log types usable one-handed on phone | Audit FAB/menus (web read-only stays) |

### P1 - Ultra-competitive differentiation (9-15 months)

| # | Feature | Acceptance criteria | Notes |
|---|---------|-------------------|-------|
| 8 | **Adaptive calorie recommendation** | Weekly suggestion from weight trend + logged intake | MacroFactor-inspired; optional toggle |
| 9 | **Weight smoothing + forecast** | 7-day EMA curve; "goal date at current rate" | Reports + home |
| 10 | **Photo food assist** | Photo -> top 3 food suggestions + portion confirm | Premium tier candidate |
| 11 | **Vitals log UI** | BP, pulse; optional glucose | `stgh_vital_log` table exists |
| 12 | **Body measurements** | Waist, body fat % on weight entry | Cronometer/Lifesum parity |
| 13 | **Sleep hours in weekly report** | 7-day avg from Health sync | Closes spreadsheet sleep column gap |
| 14 | **Home dashboard** | Today: calories, macros, water, weight, steps | Reduces "where do I look?" friction |

### P2 - Market leadership in STG niche (15-24 months)

| # | Feature | Acceptance criteria | Notes |
|---|---------|-------------------|-------|
| 15 | **Micronutrient report** | Top 10 micros vs RDA from USDA | Cronometer-lite |
| 16 | **Milestones + streaks** | Weigh-in streak, calorie logging streak | Lose It!-lite, no guilt copy |
| 17 | **Progress photos** | Attach photo to weight; gallery in report | Local storage only |
| 18 | **Consumer cloud backup** | Encrypted optional backup to STG cloud or user S3 | Privacy story intact |
| 19 | **Web write + login** | Log from browser against user account | WP API evolution |
| 20 | **Watch quick-log** | Water + weight complication | After Health sync stable |

### P3 - Optional / avoid over-investment

| Feature | Why deprioritize |
|---------|------------------|
| Native sleep staging | Sleep Cycle / Fitbit moat; integrate only |
| 14M food crowdsourced DB | MFP scale; barcode + USDA + OFF sufficient |
| Live coaching / Noom-style psychology | Different product category |
| Medication / ECG / clinical records | Apple Health hub scope |
| Social feeds and challenges | Not STG brand; privacy clash |
| Full diet meal planner | Lifesum / MFP Premium+; recipe parser is enough |

---

## Competitive scorecard (target state)

Subjective targets after P0+P1 ship:

| Matrix column | Today (1-5) | Target | vs best in class |
|---------------|-------------|--------|------------------|
| Platforms | 4 (desktop unique; web weak) | 5 | Beat on desktop; match mobile |
| Weight tracking | 3 | 5 | Match Lose It! + MacroFactor smoothing |
| Calorie / nutrient | 3 | 4 | Below MFP DB size; match on barcode + macros |
| Sleep monitoring | 1 | 3 | Match MFP "basic Health sync" - not Fitbit |
| Other health metrics | 2 | 4 | Match Cronometer vitals-lite + MFP water |
| Pricing value | 3 (proposed) | 4 | Justify $59.99 with barcode + sync + no ads |
| **Unique advantage** | 5 | 5 | Reports + admin + offline remain best-in-class |

**Overall:** Ultra competitive = **4+ average** on logging columns while **keeping 5** on privacy/reports/admin.

---

## Implementation map (stg_health codebase)

| Feature area | Likely touch points |
|--------------|---------------------|
| Barcode | `lib/features/food/`, `food_item_repository.dart`, catalog import |
| Health sync | New `lib/features/health_sync/`; platform channels; profile settings |
| Water | `stgh_daily_*` or new table; home + food UI |
| Macros | `profile_page.dart`, daily aggregation views, report builders |
| Vitals | `stgh_vital_log`, new `vitals_log_page.dart`, router |
| Weight forecast | `health_report_helpers.dart`, `home_page.dart` |
| Adaptive calories | New service using weight logs + food totals |
| Entitlements | `lib/core/config/app_config.dart` (per pricing analysis) |

---

## Messaging after roadmap

**Do not claim:** "Largest food database," "best sleep tracker," "AI coach."

**Do claim:**

- "Log offline on Windows, Mac, Linux, phone, and tablet - your data stays on your device."
- "Scan, search, or describe a recipe - three fast ways to log."
- "Print a doctor-ready health summary in one tap."
- "Manage the whole household from one admin account."
- "Syncs with Apple Health and Google Fit - no vendor lock-in."

---

## Related documents

| Document | Purpose |
|----------|---------|
| [2026-06-07_Health_and_Nutrition_Apps_Comparison.xlsx](2026-06-07_Health_and_Nutrition_Apps_Comparison.xlsx) | Source comparison matrix |
| [2026-06-07_stg_health_pricing_analysis.md](2026-06-07_stg_health_pricing_analysis.md) | Tier pricing and gating |
| [2026-06-04_STG_app_store_trial_and_licensing.md](2026-06-04_STG_app_store_trial_and_licensing.md) | Trial and entitlements |
| `stg_health/docs/2026-05-29_health_report_recommendations.md` | Report product spec |
| `stg_health/docs/stg_health_user_guide.md` | Current feature inventory |

---

## Summary

To stand ultra competitive against the apps in the comparison spreadsheet, STG Health must **close three perception gaps**: no barcode, no health-platform sync, and no water/sleep/macro daily surface. It must **amplify three existing moats**: offline desktop, clinical PDF reports, and household admin.

**Minimum viable competitiveness:** P0 list (barcode, Health sync, water, macros, target weight). 
**Ultra competitive:** P0 + P1 (adaptive calories, smoothing/forecast, vitals UI, photo assist, dashboard). 
**Category leader in STG niche:** P2 while refusing to become Apple Health or Sleep Cycle.

---

*Prepared 2026-06-07 from comparison spreadsheet and STG Health codebase review.*
