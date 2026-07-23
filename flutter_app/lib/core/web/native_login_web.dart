import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

/// Platform view type for the inline native login form on web.
const nativeLoginInlineViewType = 'agatha-native-login-inline';

bool _inlineViewRegistered = false;

/// Registers the [HtmlElementView] factory that mounts `#agatha-native-login`.
void ensureNativeLoginInlineViewRegistered() {
  if (_inlineViewRegistered) return;
  _inlineViewRegistered = true;

  ui_web.platformViewRegistry.registerViewFactory(nativeLoginInlineViewType, (
    int viewId,
  ) {
    final container = web.document.createElement('div') as web.HTMLDivElement;
    container.style.width = '100%';

    final root = web.document.getElementById('agatha-native-login');
    if (root != null) {
      container.append(root);
    }

    return container;
  });
}

/// Handle to the JS controller object defined in `web/index.html`
/// (`window.agathaNativeLogin`). Null when the markup is absent.
@JS('agathaNativeLogin')
external _NativeLoginController? get _controller;

extension type _NativeLoginController._(JSObject _) implements JSObject {
  external void configure(
    JSString emailLabel,
    JSString passwordLabel,
    JSString signInLabel,
    JSString forgotLabel,
  );
  external void attach();
  external void detach();
  external void setError(JSString message);
  external void setBusy(JSBoolean busy);
  external set onSubmit(JSFunction value);
  external set onForgot(JSFunction value);
}

/// Web implementation that drives the native HTML login `<form>` so that
/// password-manager browser extensions can detect and autofill it.
///
/// Authentication itself stays in Dart: the JS form only sources credentials
/// and invokes the registered Dart callbacks. Dart then drives the form's
/// busy/error state once the login future settles.
class NativeLogin {
  bool get isAvailable => _controller != null;

  void attachInline({
    required String emailLabel,
    required String passwordLabel,
    required String signInLabel,
    required String forgotLabel,
    required void Function(String email, String password) onSubmit,
    required void Function() onForgot,
  }) {
    final c = _controller;
    if (c == null) return;
    c.onSubmit = ((JSString e, JSString p) => onSubmit(
      e.toDart,
      p.toDart,
    )).toJS;
    c.onForgot = (() => onForgot()).toJS;
    c.configure(
      emailLabel.toJS,
      passwordLabel.toJS,
      signInLabel.toJS,
      forgotLabel.toJS,
    );
    c.attach();
  }

  void detach() => _controller?.detach();

  void setError(String message) => _controller?.setError(message.toJS);

  void setBusy(bool busy) => _controller?.setBusy(busy.toJS);
}

/// Returns the platform implementation of [NativeLogin].
NativeLogin createNativeLogin() => NativeLogin();
