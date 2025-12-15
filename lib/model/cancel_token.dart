/// Simple cancellation token for async operations
/// Prevents race conditions when user navigates away or triggers rapid refreshes
class CancelToken {
  bool _isCancelled = false;

  /// Check if this token has been cancelled
  bool get isCancelled => _isCancelled;

  /// Cancel all operations using this token
  void cancel() {
    _isCancelled = true;
  }

  /// Reset the token for reuse
  void reset() {
    _isCancelled = false;
  }
}
