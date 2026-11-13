import 'dart:convert';

import 'package:http/http.dart' as http;

class SupportStaffApiException implements Exception {
  SupportStaffApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  bool get isForbidden => statusCode == 403;
  bool get isUnauthorized => statusCode == 401;
}

class SupportStaffOutboxAlert {
  const SupportStaffOutboxAlert({required this.kind, required this.status});

  final String kind;
  final String status;

  factory SupportStaffOutboxAlert.fromJson(Map<String, dynamic> json) {
    return SupportStaffOutboxAlert(
      kind: json['kind']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class SupportStaffTicketSummary {
  const SupportStaffTicketSummary({
    required this.id,
    required this.reference,
    required this.category,
    required this.title,
    required this.signedIn,
    required this.reporterEmail,
    required this.createdAt,
    this.githubIssueNumber,
    this.outboxAlerts = const [],
  });

  final String id;
  final String reference;
  final String category;
  final String title;
  final bool signedIn;
  final String reporterEmail;
  final String? createdAt;
  final int? githubIssueNumber;
  final List<SupportStaffOutboxAlert> outboxAlerts;

  factory SupportStaffTicketSummary.fromJson(Map<String, dynamic> json) {
    final alerts = json['outbox_alerts'];
    return SupportStaffTicketSummary(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      signedIn: json['signed_in'] == true,
      reporterEmail: json['reporter_email']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      githubIssueNumber: json['github_issue_number'] is num
          ? (json['github_issue_number'] as num).toInt()
          : null,
      outboxAlerts: alerts is List
          ? alerts
                .whereType<Map<String, dynamic>>()
                .map(SupportStaffOutboxAlert.fromJson)
                .toList()
          : const [],
    );
  }
}

class SupportStaffOutboxRow {
  const SupportStaffOutboxRow({
    required this.id,
    required this.kind,
    required this.status,
    required this.attempts,
    this.githubIssueNumber,
    this.lastError,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String kind;
  final String status;
  final int attempts;
  final int? githubIssueNumber;
  final String? lastError;
  final String? createdAt;
  final String? updatedAt;

  factory SupportStaffOutboxRow.fromJson(Map<String, dynamic> json) {
    return SupportStaffOutboxRow(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      attempts: json['attempts'] is num ? (json['attempts'] as num).toInt() : 0,
      githubIssueNumber: json['github_issue_number'] is num
          ? (json['github_issue_number'] as num).toInt()
          : null,
      lastError: json['last_error']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class SupportStaffAttachment {
  const SupportStaffAttachment({
    required this.id,
    required this.mime,
    required this.bytes,
    this.createdAt,
  });

  final String id;
  final String mime;
  final int bytes;
  final String? createdAt;

  factory SupportStaffAttachment.fromJson(Map<String, dynamic> json) {
    return SupportStaffAttachment(
      id: json['id']?.toString() ?? '',
      mime: json['mime']?.toString() ?? '',
      bytes: json['bytes'] is num ? (json['bytes'] as num).toInt() : 0,
      createdAt: json['created_at']?.toString(),
    );
  }
}

class SupportStaffTicketDetail {
  const SupportStaffTicketDetail({
    required this.id,
    required this.reference,
    required this.category,
    required this.title,
    required this.description,
    required this.signedIn,
    required this.reporterEmail,
    required this.locale,
    this.userId,
    this.expected,
    this.actual,
    this.steps,
    this.frequency,
    this.context = const {},
    this.createdAt,
    this.githubIssueNumber,
  });

  final String id;
  final String reference;
  final String? userId;
  final String category;
  final String title;
  final String description;
  final bool signedIn;
  final String reporterEmail;
  final String? expected;
  final String? actual;
  final String? steps;
  final String? frequency;
  final Map<String, dynamic> context;
  final String locale;
  final String? createdAt;
  final int? githubIssueNumber;

  factory SupportStaffTicketDetail.fromJson(Map<String, dynamic> json) {
    final ctx = json['context'];
    return SupportStaffTicketDetail(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      signedIn: json['signed_in'] == true,
      reporterEmail: json['reporter_email']?.toString() ?? '',
      expected: json['expected']?.toString(),
      actual: json['actual']?.toString(),
      steps: json['steps']?.toString(),
      frequency: json['frequency']?.toString(),
      context: ctx is Map<String, dynamic> ? ctx : const {},
      locale: json['locale']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      githubIssueNumber: json['github_issue_number'] is num
          ? (json['github_issue_number'] as num).toInt()
          : null,
    );
  }
}

class SupportStaffTicketDetailResponse {
  const SupportStaffTicketDetailResponse({
    required this.ticket,
    required this.attachments,
    required this.outbox,
  });

  final SupportStaffTicketDetail ticket;
  final List<SupportStaffAttachment> attachments;
  final List<SupportStaffOutboxRow> outbox;

  factory SupportStaffTicketDetailResponse.fromJson(Map<String, dynamic> json) {
    final ticketJson = json['ticket'];
    final attachments = json['attachments'];
    final outbox = json['outbox'];
    return SupportStaffTicketDetailResponse(
      ticket: ticketJson is Map<String, dynamic>
          ? SupportStaffTicketDetail.fromJson(ticketJson)
          : const SupportStaffTicketDetail(
              id: '',
              reference: '',
              category: '',
              title: '',
              description: '',
              signedIn: false,
              reporterEmail: '',
              locale: '',
            ),
      attachments: attachments is List
          ? attachments
                .whereType<Map<String, dynamic>>()
                .map(SupportStaffAttachment.fromJson)
                .toList()
          : const [],
      outbox: outbox is List
          ? outbox
                .whereType<Map<String, dynamic>>()
                .map(SupportStaffOutboxRow.fromJson)
                .toList()
          : const [],
    );
  }
}

class SupportStaffApi {
  SupportStaffApi({
    required this.baseUrl,
    required this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String accessToken;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  Never _throwForResponse(http.Response response) {
    var message = 'Request failed';
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        message = decoded['error']?.toString() ?? message;
      }
    } catch (_) {
      // keep default
    }
    throw SupportStaffApiException(
      statusCode: response.statusCode,
      message: message,
    );
  }

  Future<List<SupportStaffTicketSummary>> listTickets() async {
    final response = await _client.get(
      _uri('/api/support/staff/tickets'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      _throwForResponse(response);
    }
    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['tickets'] is! List) {
      throw SupportStaffApiException(
        statusCode: response.statusCode,
        message: 'Unexpected response',
      );
    }
    return (decoded['tickets'] as List)
        .whereType<Map<String, dynamic>>()
        .map(SupportStaffTicketSummary.fromJson)
        .toList();
  }

  Future<SupportStaffTicketDetailResponse> getTicket(String ticketId) async {
    final response = await _client.get(
      _uri('/api/support/staff/tickets/$ticketId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      _throwForResponse(response);
    }
    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw SupportStaffApiException(
        statusCode: response.statusCode,
        message: 'Unexpected response',
      );
    }
    return SupportStaffTicketDetailResponse.fromJson(decoded);
  }

  void close() => _client.close();
}
