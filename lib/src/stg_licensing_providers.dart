import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stg_licensing/src/stg_licensing_config.dart';
import 'package:stg_licensing/src/stg_licensing_service.dart';
import 'package:stg_licensing/src/stg_licensing_state.dart';
import 'package:stg_licensing/src/stg_portfolio_app_id.dart';

/// Host app must override with its portfolio app id.
final stgLicensingAppIdProvider = Provider<StgPortfolioAppId>((ref) {
  throw UnimplementedError(
    'Override stgLicensingAppIdProvider in ProviderScope.',
  );
});

/// Host app must expose seeded SharedPreferences (nullable until bootstrap).
final stgLicensingPrefsProvider = Provider<SharedPreferences?>((ref) {
  throw UnimplementedError(
    'Override stgLicensingPrefsProvider in ProviderScope.',
  );
});

class StgLicensingNotifier extends Notifier<StgLicensingState> {
  Timer? _timer;

  @override
  StgLicensingState build() {
    ref.onDispose(() => _timer?.cancel());

    if (!stgTrialBuild) {
      return const StgLicensingState.notEnforced();
    }

    final prefs = ref.watch(stgLicensingPrefsProvider);
    if (prefs == null) {
      return const StgLicensingState(
        enforced: true,
        phase: StgLicensingPhase.trialPending,
        activeTier: StgPlanTier.trial,
      );
    }

    final appId = ref.watch(stgLicensingAppIdProvider);
    final current = readStgLicensingState(prefs, appId);
    _ensureTimer(current);
    return current;
  }

  void _ensureTimer(StgLicensingState current) {
    _timer?.cancel();
    if (!current.enforced) return;
    if (current.phase != StgLicensingPhase.trialActive &&
        current.phase != StgLicensingPhase.licensedActive) {
      return;
    }
    // Frequent tick so router lockout fires promptly; banner minute display
    // refreshes on its own 1-minute timer.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final prefs = ref.read(stgLicensingPrefsProvider);
    if (prefs == null) return;
    final appId = ref.read(stgLicensingAppIdProvider);
    final next = readStgLicensingState(prefs, appId);
    final wasActive = state.phase == StgLicensingPhase.trialActive ||
        state.phase == StgLicensingPhase.licensedActive;
    final isActive = next.phase == StgLicensingPhase.trialActive ||
        next.phase == StgLicensingPhase.licensedActive;
    state = next;
    if (wasActive && !isActive) {
      _timer?.cancel();
    }
  }

  Future<void> resetTrial() async {
    final prefs = ref.read(stgLicensingPrefsProvider);
    if (prefs == null) return;
    final appId = ref.read(stgLicensingAppIdProvider);
    await resetStgLicensingTrial(prefs, appId);
    final next = readStgLicensingState(prefs, appId);
    state = next;
    _ensureTimer(next);
  }

  Future<bool> activateLicenseKey(String candidate) async {
    final prefs = ref.read(stgLicensingPrefsProvider);
    if (prefs == null) return false;
    final appId = ref.read(stgLicensingAppIdProvider);
    final ok = await activateStgLicenseKey(prefs, appId, candidate);
    if (!ok) return false;
    final next = readStgLicensingState(prefs, appId);
    state = next;
    _ensureTimer(next);
    return true;
  }
}

final stgLicensingProvider =
    NotifierProvider<StgLicensingNotifier, StgLicensingState>(
  StgLicensingNotifier.new,
);

/// Whether the host app may write to its local database (false in read-only mode).
final stgCanWriteProvider = Provider<bool>((ref) {
  return ref.watch(stgLicensingProvider).canWriteToDatabase;
});

/// Whether export / backup flows that produce or overwrite files are allowed.
final stgCanExportProvider = Provider<bool>((ref) {
  return ref.watch(stgLicensingProvider).canExportData;
});
