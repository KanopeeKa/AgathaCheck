/// No-op implementation of the native login bridge for non-web platforms.
class NativeLogin {
  /// Whether the native HTML login form is available. Always false here.
  bool get isAvailable => false;

  void attachInline({
    required String emailLabel,
    required String passwordLabel,
    required String signInLabel,
    required String forgotLabel,
    required void Function(String email, String password) onSubmit,
    required void Function() onForgot,
  }) {}

  void detach() {}

  void setError(String message) {}

  void setBusy(bool busy) {}
}

/// Registers the inline native login platform view. No-op off-web.
void ensureNativeLoginInlineViewRegistered() {}

/// Platform view type for the inline native login form.
const nativeLoginInlineViewType = 'agatha-native-login-inline';

/// Returns the platform implementation of [NativeLogin].
NativeLogin createNativeLogin() => NativeLogin();
