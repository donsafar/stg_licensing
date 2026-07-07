/// Compile-time licensing flags (set via `--dart-define` on desktop trial builds).
const bool stgTrialBuild =
    bool.fromEnvironment('STG_TRIAL_BUILD', defaultValue: false);

/// QA override: minutes from first launch until trial expires (0 = use workbook days).
const int stgTrialDurationMinutes =
    int.fromEnvironment('STG_TRIAL_DURATION_MINUTES', defaultValue: 0);

/// QA override: minutes for a license activated via key (0 = one year).
const int stgLicenseDurationMinutes =
    int.fromEnvironment('STG_LICENSE_DURATION_MINUTES', defaultValue: 0);

Duration stgTrialDurationForApp(int trialDays) {
  if (stgTrialDurationMinutes > 0) {
    return Duration(minutes: stgTrialDurationMinutes);
  }
  return Duration(days: trialDays);
}

Duration stgLicenseSubscriptionDuration() {
  if (stgLicenseDurationMinutes > 0) {
    return Duration(minutes: stgLicenseDurationMinutes);
  }
  return const Duration(days: 365);
}
