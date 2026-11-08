import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pet_profile_app/features/pet_profile/data/datasources/pet_remote_datasource.dart';

void main() {
  test('updatePetWeightContext sends only weight-context keys', () async {
    final captured = <String>[];
    final ds = PetRemoteDataSourceImpl(
      baseUrl: 'http://test.local',
      client: _CaptureClient(captured),
    );

    await ds.updatePetWeightContext(
      petId: 'pet-1',
      token: 'token',
      weightReferenceValue: 4.0,
      weightReferenceAuthority: 'vet_target',
      weightManagementContext: 'vet_managed',
    );

    expect(captured, isNotEmpty);
    final body = jsonDecode(captured.first) as Map<String, dynamic>;
    expect(
      body.keys,
      containsAll([
        'weight_reference_value',
        'weight_reference_authority',
        'weight_management_context',
      ]),
    );
    expect(body.containsKey('name'), isFalse);
    expect(body.containsKey('vetId'), isFalse);
    expect(body['weight_reference_value'], 4.0);
  });
}

class _CaptureClient extends http.BaseClient {
  _CaptureClient(this.captured);

  final List<String> captured;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.Request) {
      captured.add(request.body);
    }
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          '{"id":"pet-1","name":"Rex","species":"Dog",'
          '"weight_management_context":"vet_managed",'
          '"weight_reference_value":4.0,"weight_reference_authority":"vet_target"}',
        ),
      ),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
