/// No-op implementation of the native login bridge for non-web platforms.
class NativeLogin {
  /// Whether the native HTML login overlay is available. Always false here.
  bool get isAvailable => false;

  void show({
    required String email,
    required String title,
    required String subtitle,
    required String emailLabel,
    required String passwordLabel,
    required String signInLabel,
    required String forgotLabel,
    required String dismissLabel,
    required void Function(String email, String password) onSubmit,
    required void Function() onForgot,
    required void Function() onDismiss,
  }) {}

  void hide() {}

  void setError(String message) {}

  void setBusy(bool busy) {}
}

/// Returns the platform implementation of [NativeLogin].
NativeLogin createNativeLogin() => NativeLogin();
