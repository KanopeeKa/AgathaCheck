import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/features/support/form/data/support_ticket_submit_payload.dart';
import 'package:pet_profile_app/features/support/form/data/support_tickets_api.dart';
import 'package:pet_profile_app/features/support/form/domain/support_ticket_category.dart';

void main() {
  test('submitTicket returns reference on 201', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      final body = json.decode(request.body) as Map<String, dynamic>;
      expect(body['category'], 'bug');
      expect(body['context'], isA<Map<String, dynamic>>());
      return http.Response(
        json.encode({'reference': 'AT-12345678'}),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = SupportTicketsApi(baseUrl: 'http://example', client: client);
  final reference = await api.submitTicket(
      SupportTicketSubmitPayload(
        category: SupportTicketCategory.bug,
        title: 'Title',
        description: 'Body',
        locale: 'en',
        context: const {'platform': 'web'},
        email: 'a@b.com',
      ),
    );
    expect(reference, 'AT-12345678');
    api.close();
  });
}
