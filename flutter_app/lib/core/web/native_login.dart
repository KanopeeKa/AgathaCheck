/// Facade for the native HTML login overlay bridge.
///
/// On web this resolves to an implementation that drives the real `<form>`
/// rendered in `web/index.html`, so password-manager browser extensions
/// (Proton Pass, Bitwarden, 1Password, ...) can detect and autofill the
/// login fields. On non-web platforms it resolves to a no-op stub.
export 'native_login_stub.dart'
    if (dart.library.html) 'native_login_web.dart';
