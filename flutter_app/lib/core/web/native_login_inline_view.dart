/// Inline native HTML login form for Flutter web (no-op elsewhere).
export 'native_login_inline_view_stub.dart'
    if (dart.library.html) 'native_login_inline_view_web.dart';
