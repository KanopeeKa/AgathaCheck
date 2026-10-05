/// Typed failures returned by [HealthDocumentsRepository] operations.
sealed class HealthDocumentFailure implements Exception {
  const HealthDocumentFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// HTTP 4xx from the documents API.
final class HealthDocumentClientFailure extends HealthDocumentFailure {
  const HealthDocumentClientFailure(super.message, {required this.statusCode});

  final int statusCode;
}

/// HTTP 5xx from the documents API.
final class HealthDocumentServerFailure extends HealthDocumentFailure {
  const HealthDocumentServerFailure(super.message, {required this.statusCode});

  final int statusCode;
}

/// Transport failure (no HTTP response).
final class HealthDocumentNetworkFailure extends HealthDocumentFailure {
  const HealthDocumentNetworkFailure([super.message = 'Network error']);
}

/// Session could not be refreshed after 401.
final class HealthDocumentSessionExpiredFailure extends HealthDocumentFailure {
  const HealthDocumentSessionExpiredFailure([
    super.message =
        'Your session has expired. Please reload the page and sign in again.',
  ]);
}
