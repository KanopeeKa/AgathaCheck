import 'dart:js_interop';

/// Handle to the JS controller object defined in `web/index.html`
/// (`window.agathaNativeLogin`). Null when the markup is absent.
@JS('agathaNativeLogin')
external _NativeLoginController? get _controller;

extension type _NativeLoginController._(JSObject _) implements JSObject {
  external void show(
    JSString email,
    JSString title,
    JSString subtitle,
    JSString emailLabel,
    JSString passwordLabel,
    JSString signInLabel,
    JSString forgotLabel,
    JSString dismissLabel,
  );
  external void hide();
  external void setError(JSString message);
  external void setBusy(JSBoolean busy);
  external set onSubmit(JSFunction value);
  external set onForgot(JSFunction value);
  external set onDismiss(JSFunction value);
}

/// Web implementation that drives the native HTML login `<form>` so that
/// password-manager browser extensions can detect and autofill it.
///
/// Authentication itself stays in Dart: the JS form only sources credentials
/// and invokes the registered Dart callbacks. Dart then drives the overlay's
/// busy/error/hide state once the login future settles.
class NativeLogin {
  bool get isAvailable => _controller != null;

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
  }) {
    final c = _controller;
    if (c == null) return;
    c.onSubmit = ((JSString e, JSString p) => onSubmit(
      e.toDart,
      p.toDart,
    )).toJS;
    c.onForgot = (() => onForgot()).toJS;
    c.onDismiss = (() => onDismiss()).toJS;
    c.show(
      email.toJS,
      title.toJS,
      subtitle.toJS,
      emailLabel.toJS,
      passwordLabel.toJS,
      signInLabel.toJS,
      forgotLabel.toJS,
      dismissLabel.toJS,
    );
  }

  void hide() => _controller?.hide();

  void setError(String message) => _controller?.setError(message.toJS);

  void setBusy(bool busy) => _controller?.setBusy(busy.toJS);
}

/// Returns the platform implementation of [NativeLogin].
NativeLogin createNativeLogin() => NativeLogin();
