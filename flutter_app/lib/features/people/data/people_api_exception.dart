import '../domain/entities/contact_usage.dart';

class PeopleApiException implements Exception {
  PeopleApiException({
    required this.code,
    required this.statusCode,
    this.message,
    this.usages = const [],
  });

  final String code;
  final int statusCode;
  final String? message;
  final List<ContactUsage> usages;

  @override
  String toString() => 'PeopleApiException($code, $statusCode)';
}
