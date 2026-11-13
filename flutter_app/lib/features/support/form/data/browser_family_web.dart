import 'package:web/web.dart' as web;

String detectBrowserFamily() {
  final ua = web.window.navigator.userAgent.toLowerCase();
  if (ua.contains('edg/')) return 'edge';
  if (ua.contains('firefox/')) return 'firefox';
  if (ua.contains('chrome/') && !ua.contains('edg/')) return 'chrome';
  if (ua.contains('safari/') && !ua.contains('chrome/')) return 'safari';
  return 'other';
}
