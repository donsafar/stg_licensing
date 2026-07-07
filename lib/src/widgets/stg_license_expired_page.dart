import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stg_licensing/src/stg_licensing_config.dart';
import 'package:stg_licensing/src/stg_licensing_providers.dart';
import 'package:stg_licensing/src/stg_portfolio_app_id.dart';
import 'package:stg_licensing/src/stg_portfolio_pricing.dart';

typedef StgLicenseExpiredLogoutCallback = Future<void> Function();
typedef StgLicenseExpiredCloseAppCallback = void Function();
typedef StgLicenseExpiredOnUnlockedCallback = void Function();

/// Full-screen lockout when trial or subscription has expired.
class StgLicenseExpiredPage extends ConsumerStatefulWidget {
  const StgLicenseExpiredPage({
    super.key,
    required this.companyName,
    this.onLogout,
    this.onCloseApp,
    this.onUnlocked,
  });

  final String companyName;
  final StgLicenseExpiredLogoutCallback? onLogout;
  final StgLicenseExpiredCloseAppCallback? onCloseApp;
  final StgLicenseExpiredOnUnlockedCallback? onUnlocked;

  @override
  ConsumerState<StgLicenseExpiredPage> createState() =>
      _StgLicenseExpiredPageState();
}

class _StgLicenseExpiredPageState extends ConsumerState<StgLicenseExpiredPage> {
  final _keyController = TextEditingController();
  int _secretTapCount = 0;
  bool _activating = false;
  String? _errorText;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _handleQaTap() {
    setState(() => _secretTapCount++);
    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      _showQaDialog();
    }
  }

  Future<void> _showQaDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('QA licensing controls'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(stgLicensingProvider.notifier).resetTrial();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  widget.onUnlocked?.call();
                }
              },
              icon: const Icon(Icons.restart_alt_outlined),
              label: const Text('Reset trial clock'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _activateKey() async {
    setState(() {
      _activating = true;
      _errorText = null;
    });
    final ok =
        await ref.read(stgLicensingProvider.notifier).activateLicenseKey(
              _keyController.text,
            );
    if (!mounted) return;
    setState(() => _activating = false);
    if (ok) {
      widget.onUnlocked?.call();
      return;
    }
    setState(() => _errorText = 'Invalid license key.');
  }

  @override
  Widget build(BuildContext context) {
    final appId = ref.watch(stgLicensingAppIdProvider);
    final licensing = ref.watch(stgLicensingProvider);
    final pricing = StgPortfolioPricing.forApp(appId);
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd().add_jm();
    final started = licensing.startedAt;
    final expired = licensing.expiresAt;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Log out',
              icon: const Icon(Icons.logout_outlined),
              onPressed: () => widget.onLogout!.call(),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Icon(
                    Icons.lock_clock_outlined,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your trial has ended',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Subscribe to keep using ${pricing.appId.displayName}. '
                    'Enter a license key below or choose a plan.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _infoRow(context, 'Standard', pricing.standardPriceLabel),
                          const Divider(height: 20),
                          _infoRow(context, 'Premium', pricing.premiumPriceLabel),
                          if (started != null) ...[
                            const Divider(height: 20),
                            _infoRow(
                              context,
                              'Trial started',
                              dateFormat.format(started),
                            ),
                          ],
                          if (expired != null)
                            _infoRow(
                              context,
                              'Trial ended',
                              dateFormat.format(expired),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'License key',
                      border: const OutlineInputBorder(),
                      errorText: _errorText,
                    ),
                    onSubmitted: (_) => _activateKey(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _activating ? null : _activateKey,
                    icon: _activating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.vpn_key_outlined),
                    label: const Text('Activate license'),
                  ),
                  if (stgTrialDurationMinutes > 0) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(stgLicensingProvider.notifier)
                            .resetTrial();
                        widget.onUnlocked?.call();
                      },
                      icon: const Icon(Icons.restart_alt_outlined),
                      label: const Text('Reset trial clock (QA)'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QA build — $stgTrialDurationMinutes-minute trial window',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (widget.onCloseApp != null) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: widget.onCloseApp,
                      child: Text('Close ${pricing.appId.displayName}'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _handleQaTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${widget.companyName} ${pricing.appId.displayName}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(value, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
