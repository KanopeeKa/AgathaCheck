import 'package:flutter/material.dart';

/// Undo snackbars should stay visible long enough to tap Undo, then dismiss.
///
/// Five seconds matches product spec (notifications FR-ST-4) and common
/// patterns (Gmail, Google Docs, Material snackbars with actions).
const Duration kUndoSnackBarDuration = Duration(seconds: 5);

/// Default auto-dismiss for simple feedback snackbars (no undo action).
const Duration kAppSnackBarDuration = Duration(seconds: 4);

extension AppUndoSnackBar on ScaffoldMessengerState {
  /// Shows a floating snackbar with [undoLabel], close (×), and auto-dismiss.
  void showUndoSnackBar({
    required Widget content,
    required String undoLabel,
    required VoidCallback onUndo,
    Key? snackBarKey,
    Key? undoActionKey,
    Duration? duration,
  }) {
    showSnackBar(
      SnackBar(
        key: snackBarKey,
        duration: duration ?? kUndoSnackBarDuration,
        persist: false,
        showCloseIcon: true,
        content: content,
        action: SnackBarAction(
          key: undoActionKey,
          label: undoLabel,
          onPressed: onUndo,
        ),
      ),
    );
  }

  /// Simple message snackbar with optional close control and bounded duration.
  void showAppSnackBar({
    required Widget content,
    Duration? duration,
    Key? snackBarKey,
    bool showCloseIcon = true,
  }) {
    showSnackBar(
      SnackBar(
        key: snackBarKey,
        duration: duration ?? kAppSnackBarDuration,
        showCloseIcon: showCloseIcon,
        content: content,
      ),
    );
  }
}
