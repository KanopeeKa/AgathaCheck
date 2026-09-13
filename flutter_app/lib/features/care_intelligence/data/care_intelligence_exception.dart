/// Thrown when a care intelligence API request fails.
class CareIntelligenceException implements Exception {
  const CareIntelligenceException(this.statusCode, [this.message]);

  final int statusCode;
  final String? message;

  bool get isForbidden => statusCode == 403;

  @override
  String toString() =>
      message ?? 'Care intelligence request failed ($statusCode)';
}
