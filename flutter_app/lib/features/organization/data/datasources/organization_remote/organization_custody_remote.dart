import 'dart:convert';

import '../../../domain/entities/custody_transfer.dart';
import 'organization_remote_context.dart';

class OrganizationCustodyRemote {
  OrganizationCustodyRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<Map<String, dynamic>> requestCustodyTransfer(
    String orgId,
    String petId, {
    required String transferKind,
    String? toOrgId,
    String? toUserId,
    String notes = '',
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/pets/$petId/custody-transfers',
      ),
      headers: _ctx.headers(token),
      body: json.encode({
        'transfer_kind': transferKind,
        if (toOrgId != null) 'to_org_id': toOrgId,
        if (toUserId != null) 'to_user_id': toUserId,
        'notes': notes,
      }),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to request custody transfer');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<List<CustodyTransfer>> getPendingCustodyTransfers(String token) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/custody-transfers/pending'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to load custody transfers');
    }
    final list = json.decode(response.body) as List;
    return list
        .map((e) => _mapTransfer(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> acceptCustodyTransfer(String transferId, String token) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/custody-transfers/$transferId/accept'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to accept custody transfer');
    }
  }

  Future<void> cancelCustodyTransfer(
    String transferId,
    String token, {
    String reason = '',
  }) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/custody-transfers/$transferId/cancel'),
      headers: _ctx.headers(token),
      body: json.encode({'reason': reason}),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to cancel custody transfer');
    }
  }

  Future<void> setPetHomeHidden(
    String orgId,
    String petId, {
    required bool hidden,
    required String token,
  }) async {
    final response = await _ctx.client.put(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/pets/$petId/home-hidden',
      ),
      headers: _ctx.headers(token),
      body: json.encode({'hidden': hidden}),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to update home visibility');
    }
  }

  Future<List<Map<String, dynamic>>> getHomeHiddenPets(
    String orgId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/home-hidden'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to load hidden pets');
    }
    final list = json.decode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  CustodyTransfer _mapTransfer(Map<String, dynamic> json) {
    return CustodyTransfer(
      id: json['id']?.toString() ?? '',
      petId: json['pet_id']?.toString() ?? '',
      petName: json['pet_name']?.toString(),
      transferKind: json['transfer_kind']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      fromOrgId: json['from_org_id']?.toString(),
      fromUserId: json['from_user_id']?.toString(),
      toOrgId: json['to_org_id']?.toString(),
      toUserId: json['to_user_id']?.toString(),
      notes: json['notes']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
