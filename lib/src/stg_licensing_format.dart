import 'package:stg_licensing/src/stg_licensing_state.dart';
import 'package:stg_licensing/src/stg_portfolio_app_id.dart';

/// Parsed banner text for [StgLicensingStatusBanner].
class StgLicensingBannerContent {
  const StgLicensingBannerContent.expired({
    required this.licenseType,
    this.readOnly = false,
  })  : isExpired = true,
        days = null,
        hours = null,
        minutes = null,
        showMinutes = false;

  const StgLicensingBannerContent.countdown({
    required this.licenseType,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.showMinutes,
  })  : isExpired = false,
        readOnly = false;

  final String licenseType;
  final bool isExpired;
  final bool readOnly;
  final int? days;
  final int? hours;
  final int? minutes;
  final bool showMinutes;
}

const _oneDay = Duration(days: 1);

String stgLicensingLicenseTypeLabel(StgLicensingState state) {
  if (state.phase == StgLicensingPhase.trialActive ||
      state.activeTier == StgPlanTier.trial) {
    return 'Trial';
  }
  return state.activeTier?.label ?? 'License';
}

StgLicensingBannerContent buildStgLicensingBannerContent(
  StgLicensingState state,
) {
  if (!state.enforced) {
    return const StgLicensingBannerContent.countdown(
      licenseType: '',
      days: null,
      hours: null,
      minutes: null,
      showMinutes: false,
    );
  }

  final licenseType = stgLicensingLicenseTypeLabel(state);

  if (state.phase == StgLicensingPhase.trialPending) {
    return StgLicensingBannerContent.countdown(
      licenseType: licenseType,
      days: null,
      hours: null,
      minutes: null,
      showMinutes: false,
    );
  }

  if (state.phase == StgLicensingPhase.locked) {
    return StgLicensingBannerContent.expired(
      licenseType: licenseType,
      readOnly: true,
    );
  }

  final remaining = state.remaining;
  if (remaining == null) {
    return StgLicensingBannerContent.countdown(
      licenseType: licenseType,
      days: null,
      hours: null,
      minutes: null,
      showMinutes: false,
    );
  }

  if (remaining.inSeconds <= 0) {
    return StgLicensingBannerContent.expired(licenseType: licenseType);
  }

  final showMinutes = remaining <= _oneDay;
  final totalHours = remaining.inHours;
  final days = totalHours ~/ 24;
  final hours = totalHours % 24;
  final minutes = remaining.inMinutes.remainder(60);

  return StgLicensingBannerContent.countdown(
    licenseType: licenseType,
    days: days > 0 ? days : null,
    hours: hours > 0 || !showMinutes ? hours : null,
    minutes: showMinutes ? minutes : null,
    showMinutes: showMinutes,
  );
}

/// Legacy single-line label (Tools panel, tests).
String stgLicensingBannerLabel(StgLicensingState state) {
  if (!state.enforced) return '';
  if (state.phase == StgLicensingPhase.trialPending) {
    return 'Trial — starting evaluation clock…';
  }

  final content = buildStgLicensingBannerContent(state);
  if (content.isExpired) {
    if (content.readOnly) {
      return 'Read-only — subscribe to edit your data';
    }
    return '${content.licenseType} License Expired';
  }
  if (content.licenseType.isEmpty) return '';

  final parts = <String>[];
  if (content.days != null && content.days! > 0) {
    parts.add('${content.days}d');
  }
  if (content.hours != null && content.hours! > 0) {
    parts.add('${content.hours}h');
  }
  if (content.showMinutes && content.minutes != null) {
    parts.add('${content.minutes}m');
  }
  if (parts.isEmpty) {
    parts.add('0m');
  }

  return '${content.licenseType} — ${parts.join(' ')} remaining';
}
