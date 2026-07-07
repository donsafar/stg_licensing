# stg_licensing

Shared **Safar Technology Group** portfolio licensing: trial clock, subscription tiers, pricing catalog, Riverpod providers, and UI widgets (status banner, expired / paywall page).

Used by STG Flutter apps (`stg_health`, `stg_checklist`, `stg_taskapp`, etc.).

## Package layout

| Path | Purpose |
|------|---------|
| `lib/stg_licensing.dart` | Public exports |
| `lib/src/stg_portfolio_app_id.dart` | `StgPortfolioAppId`, `StgPlanTier` |
| `lib/src/stg_portfolio_pricing.dart` | Canonical yearly pricing (single file to edit) |
| `lib/src/stg_licensing_service.dart` | Prefs, trial start, license key activation |
| `lib/src/stg_licensing_providers.dart` | `stgLicensingProvider` (Riverpod) |
| `lib/src/widgets/` | Banner, expired page |
| `docs/` | Architecture, RevenueCat planning, pricing analysis |

## Add to an app

### Local path (monorepo / dev)

```yaml
dependencies:
  stg_licensing:
    path: ../packages/licensing
```

### Git dependency (CI / other machines)

```yaml
dependencies:
  stg_licensing:
    git:
      url: https://github.com/donsafar/stg_licensing.git
      ref: main
```

Wire overrides in `ProviderScope` (see `stg_health/lib/providers/stg_licensing_config.dart`).

## Trial QA builds

Host apps pass compile-time flags:

```text
--dart-define=STG_TRIAL_BUILD=true
--dart-define=STG_TRIAL_DURATION_MINUTES=5
```

## Tests

```bash
flutter test
```

## Docs

- `docs/revenuecat_portfolio_implementation_guide.md` — future store billing (RevenueCat)
- `docs/7_day_single_device_trial_architecture.md` — tamper-resistant trial design (reference)

## License

Proprietary — Safar Technology Group. All rights reserved.
