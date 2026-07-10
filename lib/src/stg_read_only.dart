/// Thrown when a database write or export is attempted in read-only mode.
class StgReadOnlyException implements Exception {
  const StgReadOnlyException([
    this.message = stgReadOnlyDefaultMessage,
  ]);

  final String message;

  @override
  String toString() => 'StgReadOnlyException: $message';
}

const stgReadOnlyDefaultMessage =
    'This app is in read-only mode. Subscribe to make changes.';

/// Asserts [canWrite] or throws [StgReadOnlyException].
void stgAssertCanWriteDatabase(bool canWrite, {String? message}) {
  if (!canWrite) {
    throw StgReadOnlyException(message ?? const StgReadOnlyException().message);
  }
}
