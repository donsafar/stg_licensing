import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stg_licensing/src/stg_license_key.dart';
import 'package:stg_licensing/src/stg_licensing_config.dart';
import 'package:stg_licensing/src/stg_licensing_state.dart';
import 'package:stg_licensing/src/stg_portfolio_app_id.dart';
import 'package:stg_licensing/src/stg_portfolio_pricing.dart';

class StgLicensingPrefsKeys {
  const StgLicensingPrefsKeys(this.prefix);

  final String prefix;

  String get trialStartedAtMs => '${prefix}_trial_started_at_ms';
  String get licenseTierIndex => '${prefix}_license_tier_index';
  String get licenseExpiresAtMs => '${prefix}_license_expires_at_ms';
  String get selectedPlanIndex => '${prefix}_selected_plan_index';

  /// Legacy QA flag from early stg_health trial builds.
  String get legacyTrialPremiumUnlocked => '${prefix}_trial_premium_unlocked';
}

bool _controlsEnabled() => stgTrialBuild || !kReleaseMode;

StgLicensingPrefsKeys stgLicensingPrefsKeysFor(StgPortfolioAppId appId) {
  return StgLicensingPrefsKeys(appId.prefsPrefix);
}

StgPlanTier? _readLicenseTier(SharedPreferences prefs, StgLicensingPrefsKeys keys) {
  final index = prefs.getInt(keys.licenseTierIndex);
  if (index == null || index < 0 || index >= StgPlanTier.values.length) {
    return null;
  }
  final tier = StgPlanTier.values[index];
  if (tier == StgPlanTier.trial) return null;
  return tier;
}

DateTime? _readLicenseExpiresAt(SharedPreferences prefs, StgLicensingPrefsKeys keys) {
  final ms = prefs.getInt(keys.licenseExpiresAtMs);
  if (ms == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(ms);
}

void _migrateLegacyPremiumUnlock(SharedPreferences prefs, StgLicensingPrefsKeys keys) {
  if (prefs.getBool(keys.legacyTrialPremiumUnlocked) != true) return;
  if (prefs.containsKey(keys.licenseTierIndex)) return;

  final expiresAt = DateTime.now().add(stgLicenseSubscriptionDuration());
  prefs.setInt(keys.licenseTierIndex, StgPlanTier.premium.index);
  prefs.setInt(keys.licenseExpiresAtMs, expiresAt.millisecondsSinceEpoch);
  prefs.remove(keys.legacyTrialPremiumUnlocked);
}

StgLicensingState readStgLicensingState(
  SharedPreferences prefs,
  StgPortfolioAppId appId,
) {
  if (!stgTrialBuild) return const StgLicensingState.notEnforced();

  final keys = stgLicensingPrefsKeysFor(appId);
  _migrateLegacyPremiumUnlock(prefs, keys);

  final licenseTier = _readLicenseTier(prefs, keys);
  final licenseExpiresAt = _readLicenseExpiresAt(prefs, keys);
  if (licenseTier != null && licenseExpiresAt != null) {
    final licenseActive = DateTime.now().isBefore(licenseExpiresAt);
    if (licenseActive) {
      return StgLicensingState(
        enforced: true,
        phase: StgLicensingPhase.licensedActive,
        activeTier: licenseTier,
        startedAt: null,
        expiresAt: licenseExpiresAt,
      );
    }
    return StgLicensingState(
      enforced: true,
      phase: StgLicensingPhase.locked,
      activeTier: licenseTier,
      startedAt: null,
      expiresAt: licenseExpiresAt,
    );
  }

  final pricing = StgPortfolioPricing.forApp(appId);
  final startedMs = prefs.getInt(keys.trialStartedAtMs);
  if (startedMs == null) {
    return const StgLicensingState(
      enforced: true,
      phase: StgLicensingPhase.trialPending,
      activeTier: StgPlanTier.trial,
    );
  }

  final startedAt = DateTime.fromMillisecondsSinceEpoch(startedMs);
  final expiresAt = startedAt.add(stgTrialDurationForApp(pricing.trialDays));
  final trialActive = DateTime.now().isBefore(expiresAt);

  return StgLicensingState(
    enforced: true,
    phase: trialActive ? StgLicensingPhase.trialActive : StgLicensingPhase.locked,
    activeTier: StgPlanTier.trial,
    startedAt: startedAt,
    expiresAt: expiresAt,
  );
}

Future<void> ensureStgLicensingTrialStarted(
  SharedPreferences prefs,
  StgPortfolioAppId appId,
) async {
  if (!_controlsEnabled()) return;
  final keys = stgLicensingPrefsKeysFor(appId);
  if (prefs.containsKey(keys.trialStartedAtMs)) return;
  if (_readLicenseTier(prefs, keys) != null) return;
  await prefs.setInt(
    keys.trialStartedAtMs,
    DateTime.now().millisecondsSinceEpoch,
  );
}

Future<void> resetStgLicensingTrial(
  SharedPreferences prefs,
  StgPortfolioAppId appId,
) async {
  if (!_controlsEnabled()) return;
  final keys = stgLicensingPrefsKeysFor(appId);
  await prefs.remove(keys.legacyTrialPremiumUnlocked);
  await prefs.remove(keys.licenseTierIndex);
  await prefs.remove(keys.licenseExpiresAtMs);
  await prefs.remove(keys.trialStartedAtMs);
  await prefs.setInt(keys.selectedPlanIndex, StgPlanTier.trial.index);
  await ensureStgLicensingTrialStarted(prefs, appId);
}

Future<bool> activateStgLicenseKey(
  SharedPreferences prefs,
  StgPortfolioAppId appId,
  String candidate,
) async {
  if (!_controlsEnabled()) return false;
  final activation = resolveLicenseKeyActivation(candidate);
  if (activation == null) return false;

  final keys = stgLicensingPrefsKeysFor(appId);
  final expiresAt = DateTime.now().add(stgLicenseSubscriptionDuration());
  await prefs.setInt(keys.licenseTierIndex, activation.tier.index);
  await prefs.setInt(keys.licenseExpiresAtMs, expiresAt.millisecondsSinceEpoch);
  await prefs.setInt(keys.selectedPlanIndex, activation.tier.index);
  await prefs.remove(keys.legacyTrialPremiumUnlocked);
  return true;
}
