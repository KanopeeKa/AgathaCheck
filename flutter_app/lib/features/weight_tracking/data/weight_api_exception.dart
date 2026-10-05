class WeightApiException implements Exception {
  WeightApiException(this.statusCode, this.code, [this.message]);

  final int statusCode;
  final String? code;
  final String? message;

  @override
  String toString() => 'WeightApiException($statusCode, $code)';
}
