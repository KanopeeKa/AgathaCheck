import 'package:http/http.dart' show ClientException;

/// True when the HTTP client failed before a response (connectivity / DNS / TLS).
bool isPetListTransportFailure(Object error) => error is ClientException;
