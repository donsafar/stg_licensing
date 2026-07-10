import 'package:stg_licensing/src/stg_access_mode.dart';
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

  /// True when trial or subscription has ended (read-only mode, not full app lockout).
  bool get isLocked => phase == StgLicensingPhase.locked;

  bool get isReadOnly => enforced && phase == StgLicensingPhase.locked;

  bool get isTrialActive => phase == StgLicensingPhase.trialActive;

  bool get isLicensedActive => phase == StgLicensingPhase.licensedActive;

  StgAccessMode get accessMode {
    if (!enforced) return StgAccessMode.full;
    return switch (phase) {
      StgLicensingPhase.locked => StgAccessMode.readOnly,
      StgLicensingPhase.notEnforced => StgAccessMode.full,
      StgLicensingPhase.trialPending ||
      StgLicensingPhase.trialActive ||
      StgLicensingPhase.licensedActive =>
        StgAccessMode.full,
    };
  }

  /// Whether the app may insert, update, or delete rows in its local database.
  bool get canWriteToDatabase => accessMode == StgAccessMode.full;

  /// Whether export / backup that writes files or mutates data is allowed.
  bool get canExportData => canWriteToDatabase;
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
