import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stg_licensing/src/stg_licensing_format.dart';
import 'package:stg_licensing/src/stg_licensing_providers.dart';
import 'package:stg_licensing/src/stg_licensing_state.dart';

/// Top-of-app banner for trial or licensed subscription countdown.
class StgLicensingStatusBanner extends ConsumerStatefulWidget {
  const StgLicensingStatusBanner({
    super.key,
    this.onReadOnlyTap,
  });

  /// Called when the user taps the banner in read-only mode (trial/subscription ended).
  final VoidCallback? onReadOnlyTap;

  @override
  ConsumerState<StgLicensingStatusBanner> createState() =>
      _StgLicensingStatusBannerState();
}

class _StgLicensingStatusBannerState
    extends ConsumerState<StgLicensingStatusBanner>
    with SingleTickerProviderStateMixin {
  Timer? _minuteTimer;
  late final AnimationController _blinkController;
  late final Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _blinkAnimation = CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  void _syncMinuteTimer(StgLicensingState licensing) {
    final shouldRun = licensing.enforced &&
        (licensing.phase == StgLicensingPhase.trialActive ||
            licensing.phase == StgLicensingPhase.licensedActive ||
            licensing.phase == StgLicensingPhase.locked);

    if (!shouldRun) {
      _minuteTimer?.cancel();
      _minuteTimer = null;
      return;
    }

    if (_minuteTimer != null) return;

    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final licensing = ref.watch(stgLicensingProvider);
    _syncMinuteTimer(licensing);

    if (!licensing.enforced) return const SizedBox.shrink();

    final showBanner = licensing.phase == StgLicensingPhase.trialActive ||
        licensing.phase == StgLicensingPhase.licensedActive ||
        licensing.phase == StgLicensingPhase.locked ||
        licensing.phase == StgLicensingPhase.trialPending;

    if (!showBanner) return const SizedBox.shrink();

    final content = buildStgLicensingBannerContent(licensing);
    if (content.licenseType.isEmpty && !content.isExpired) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isLicensed = licensing.phase == StgLicensingPhase.licensedActive;
    final isReadOnly = licensing.isReadOnly;
    final isExpired =
        content.isExpired || licensing.phase == StgLicensingPhase.locked;
    final onReadOnlyTap = isReadOnly ? widget.onReadOnlyTap : null;

    final bannerColor = (isExpired
            ? theme.colorScheme.errorContainer
            : isLicensed
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.primaryContainer)
        .withValues(alpha: 0.55);
    final onBannerColor = isExpired
        ? theme.colorScheme.onErrorContainer
        : isLicensed
            ? theme.colorScheme.onSecondaryContainer
            : theme.colorScheme.onPrimaryContainer;

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isExpired
                ? Icons.error_outline
                : isLicensed
                    ? Icons.verified_outlined
                    : Icons.schedule_outlined,
            size: 18,
            color: onBannerColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BannerText(
              content: content,
              pending: licensing.phase == StgLicensingPhase.trialPending,
              readOnlyTappable: onReadOnlyTap != null,
              blinkAnimation: _blinkAnimation,
              textStyle: theme.textTheme.bodySmall?.copyWith(
                color: onBannerColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onReadOnlyTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: onBannerColor),
          ],
        ],
      ),
    );

    return Material(
      color: bannerColor,
      child: onReadOnlyTap == null
          ? row
          : Semantics(
              button: true,
              label: 'Read-only mode. View subscription options.',
              child: InkWell(
                onTap: onReadOnlyTap,
                child: row,
              ),
            ),
    );
  }
}

class _BannerText extends StatelessWidget {
  const _BannerText({
    required this.content,
    required this.pending,
    required this.readOnlyTappable,
    required this.blinkAnimation,
    required this.textStyle,
  });

  final StgLicensingBannerContent content;
  final bool pending;
  final bool readOnlyTappable;
  final Animation<double> blinkAnimation;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    if (pending) {
      return Text(
        'Trial — starting evaluation clock…',
        style: textStyle,
      );
    }

    if (content.isExpired) {
      return Text(
        content.readOnly
            ? (readOnlyTappable
                ? 'Read-only — tap to subscribe and edit your data'
                : 'Read-only — subscribe to edit your data')
            : '${content.licenseType} License Expired',
        style: textStyle,
      );
    }

    final spans = <InlineSpan>[
      TextSpan(text: '${content.licenseType} — '),
    ];

    if (content.days != null && content.days! > 0) {
      spans.add(TextSpan(text: '${content.days}d '));
    }
    if (content.hours != null && content.hours! > 0) {
      spans.add(TextSpan(text: '${content.hours}h '));
    }
    if (content.showMinutes && content.minutes != null) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: FadeTransition(
            opacity: blinkAnimation,
            child: Text('${content.minutes}m ', style: textStyle),
          ),
        ),
      );
    }
    spans.add(TextSpan(text: 'remaining', style: textStyle));

    return Text.rich(TextSpan(style: textStyle, children: spans));
  }
}
