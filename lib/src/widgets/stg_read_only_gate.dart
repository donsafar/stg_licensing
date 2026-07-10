import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stg_licensing/src/stg_licensing_providers.dart';
import 'package:stg_licensing/src/stg_read_only.dart';

typedef StgReadOnlyBlockedCallback = void Function(BuildContext context);

/// Wraps a control that mutates data; invokes [onBlocked] or shows a snackbar when read-only.
class StgReadOnlyGate extends ConsumerWidget {
  const StgReadOnlyGate({
    super.key,
    required this.child,
    this.onBlocked,
    this.blockedMessage = stgReadOnlyDefaultMessage,
  });

  final Widget child;
  final StgReadOnlyBlockedCallback? onBlocked;
  final String blockedMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = ref.watch(stgCanWriteProvider);
    if (canWrite) return child;

    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: 0.45, child: child),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(onTap: () => _notifyBlocked(context)),
          ),
        ),
      ],
    );
  }

  void _notifyBlocked(BuildContext context) {
    if (onBlocked != null) {
      onBlocked!(context);
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(blockedMessage)));
  }
}

/// Runs [action] when writes are allowed; otherwise notifies the user.
Future<T?> stgRunIfCanWrite<T>({
  required WidgetRef ref,
  required BuildContext context,
  required Future<T> Function() action,
  String? blockedMessage,
}) async {
  if (!ref.read(stgCanWriteProvider)) {
    final message = blockedMessage ?? stgReadOnlyDefaultMessage;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
    return null;
  }
  return action();
}
