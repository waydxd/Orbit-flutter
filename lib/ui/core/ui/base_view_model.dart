import 'package:flutter/foundation.dart';

/// Base view model class for all ViewModels
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get error => _error;

  /// Check if view model is disposed
  bool get isDisposed => _isDisposed;

  /// Set loading state
  void setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void setError(String? error) {
    if (_isDisposed) return;
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    if (_isDisposed) return;
    _error = null;
    notifyListeners();
  }

  /// Execute async operation with loading and error handling
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    bool showLoading = true,
    bool clearErrorOnStart = true,
  }) async {
    if (_isDisposed) return null;

    try {
      if (clearErrorOnStart) clearError();
      if (showLoading) setLoading(true);

      final result = await operation();
      return result;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
