import 'dart:convert';

import '../../../data/datasources/organization_remote/organization_remote_context.dart';

class FosterHomeVisitRemote {
  FosterHomeVisitRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<Map<String, dynamic>> loadVisits(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-home-visits/$fosterParentId',
      ),
      headers: _ctx.headers(token),
    );
    final data = json.decode(response.body);
    if (response.statusCode >= 400) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'Failed to load foster home visits');
    }
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> loadStatus(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-home-visits/$fosterParentId/status',
      ),
      headers: _ctx.headers(token),
    );
    final data = json.decode(response.body);
    if (response.statusCode >= 400) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'Failed to load foster home visit status');
    }
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> scheduleVisit(
    String orgId,
    String fosterParentId, {
    required String visitDate,
    required String visitTime,
    String address = '',
    String notes = '',
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-home-visits/$fosterParentId/schedule',
      ),
      headers: _ctx.headers(token),
      body: json.encode({
        'visit_date': visitDate,
        'visit_time': visitTime,
        if (address.isNotEmpty) 'address': address,
        if (notes.isNotEmpty) 'notes': notes,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode >= 400) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'Failed to schedule foster home visit');
    }
    final visit = (data as Map)['visit'];
    if (visit is! Map) {
      throw Exception('Invalid foster home visit schedule response');
    }
    return Map<String, dynamic>.from(visit);
  }

  Future<Map<String, dynamic>> rescheduleVisit(
    String orgId,
    String visitId, {
    required String visitDate,
    required String visitTime,
    String? address,
    String? notes,
    required String token,
  }) async {
    final response = await _ctx.client.patch(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-home-visits/$visitId/reschedule',
      ),
      headers: _ctx.headers(token),
      body: json.encode({
        'visit_date': visitDate,
        'visit_time': visitTime,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode >= 400) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'Failed to reschedule foster home visit');
    }
    final visit = (data as Map)['visit'];
    if (visit is! Map) {
      throw Exception('Invalid foster home visit reschedule response');
    }
    return Map<String, dynamic>.from(visit);
  }

  Future<Map<String, dynamic>> cancelVisit(
    String orgId,
    String visitId, {
    String cancelReason = '',
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-home-visits/$visitId/cancel',
      ),
      headers: _ctx.headers(token),
      body: json.encode({
        if (cancelReason.isNotEmpty) 'cancel_reason': cancelReason,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode >= 400) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'Failed to cancel foster home visit');
    }
    final visit = (data as Map)['visit'];
    if (visit is! Map) {
      throw Exception('Invalid foster home visit cancel response');
    }
    return Map<String, dynamic>.from(visit);
  }

  Future<Map<String, dynamic>> validateVisit(
    String orgId,
    String visitId, {
    required String outcome,
    String outcomeReason = '',
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-home-visits/$visitId/validate',
      ),
      headers: _ctx.headers(token),
      body: json.encode({
        'outcome': outcome,
        if (outcomeReason.isNotEmpty) 'outcome_reason': outcomeReason,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode >= 400) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'Failed to validate foster home visit');
    }
    final visit = (data as Map)['visit'];
    if (visit is! Map) {
      throw Exception('Invalid foster home visit validate response');
    }
    return Map<String, dynamic>.from(visit);
  }
}
