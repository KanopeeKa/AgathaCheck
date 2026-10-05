// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool readOsPushPermissionDenied() {
  try {
    return html.Notification.permission == 'denied';
  } catch (_) {
    return false;
  }
}
