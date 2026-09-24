import 'package:http/http.dart' show ClientException;

/// True when a pet list remote fetch failed for connectivity, not app/data errors.
bool isPetListTransportFailure(Object error) {
  if (error is ClientException) {
    return true;
  }
  final description = error.toString();
  return description.contains('SocketException') ||
      description.contains('Failed host lookup') ||
      description.contains('Connection refused') ||
      description.contains('Network is unreachable');
}
