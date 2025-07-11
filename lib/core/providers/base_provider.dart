import 'package:flutter/material.dart';

/// An abstract base class for providers that safely handles `notifyListeners`
/// after a provider has been disposed.
///
/// This prevents the "A ChangeNotifier was used after being disposed" error
/// that can occur when async operations complete after a widget has been
/// removed from the tree.
abstract class BaseProvider with ChangeNotifier {
  bool _isDisposed = false;

  /// A flag to check if the provider has been disposed.
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Notifies listeners only if the provider has not been disposed.
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
