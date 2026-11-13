import 'browser_family_stub.dart'
    if (dart.library.js_interop) 'browser_family_web.dart'
    as impl;

String detectBrowserFamily() => impl.detectBrowserFamily();
