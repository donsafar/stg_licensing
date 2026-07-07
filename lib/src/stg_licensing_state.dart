import 'package:stg_licensing/src/stg_portfolio_app_id.dart';

enum StgLicensingPhase {
  notEnforced,
  trialPending,
  trialActive,
  locked,
  licensedActive,
}

class StgLicensingState {
  const StgLicensingState({
    required this.enforced,
    required this.phase,
    this.activeTier,
    this.startedAt,
    this.expiresAt,
  });

  const StgLicensingState.notEnforced()
      : enforced = false,
        phase = StgLicensingPhase.notEnforced,
        activeTier = null,
        startedAt = null,
        expiresAt = null;

  final bool enforced;
  final StgLicensingPhase phase;
  final StgPlanTier? activeTier;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  bool get isLocked => phase == StgLicensingPhase.locked;

  bool get isTrialActive => phase == StgLicensingPhase.trialActive;

  bool get isLicensedActive => phase == StgLicensingPhase.licensedActive;

  Duration? get remaining {
    if (!enforced || expiresAt == null) return null;
    if (phase != StgLicensingPhase.trialActive &&
        phase != StgLicensingPhase.licensedActive) {
      return null;
    }
    final left = expiresAt!.difference(DateTime.now());
    if (left.isNegative) return Duration.zero;
    return left;
  }
}
