import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/organization/domain/entities/foster_request.dart';

void main() {
  group('FosterRequestStatus', () {
    test('fromWire and toWire round-trip', () {
      expect(FosterRequestStatus.fromWire('sent'), FosterRequestStatus.sent);
      expect(
        FosterRequestStatus.fromWire('cancelled'),
        FosterRequestStatus.cancelled,
      );
      expect(FosterRequestStatus.fromWire('draft'), FosterRequestStatus.draft);
      expect(
        FosterRequestStatus.fromWire('unknown'),
        FosterRequestStatus.draft,
      );
      expect(FosterRequestStatus.sent.toWire(), 'sent');
    });
  });

  group('FosterResponseType', () {
    test('fromWire and toWire round-trip', () {
      expect(
        FosterResponseType.fromWire('can_help'),
        FosterResponseType.canHelp,
      );
      expect(
        FosterResponseType.fromWire('cannot_help'),
        FosterResponseType.cannotHelp,
      );
      expect(
        FosterResponseType.fromWire('pending'),
        FosterResponseType.pending,
      );
      expect(FosterResponseType.canHelp.toWire(), 'can_help');
      expect(FosterResponseType.cannotHelp.toWire(), 'cannot_help');
    });
  });

  group('FosterRequestResponseSummary', () {
    test('fromJson parses counts', () {
      final summary = FosterRequestResponseSummary.fromJson({
        'pending': 2,
        'can_help': '1',
        'cannot_help': 0,
      });

      expect(summary.pending, 2);
      expect(summary.canHelp, 1);
      expect(summary.cannotHelp, 0);
    });

    test('fromJson tolerates null', () {
      expect(
        FosterRequestResponseSummary.fromJson(null),
        const FosterRequestResponseSummary(),
      );
    });
  });

  group('FosterRequest.fromJson', () {
    test('parses nested pets, targets, and responses', () {
      final request = FosterRequest.fromJson({
        'id': 'fr-1',
        'organization_id': 'org-1',
        'message': 'Need foster',
        'status': 'sent',
        'created_by': 'user-1',
        'sent_at': '2025-06-01T10:00:00.000Z',
        'pet_ids': ['pet-1'],
        'pets': [
          {'pet_id': 'pet-1', 'pet_name': 'Bella', 'species': 'Dog'},
        ],
        'targets': [
          {
            'org_foster_parent_id': 'fp-1',
            'display_name': 'Alex',
            'email': 'alex@example.com',
            'approval_state': 'approved',
            'opt_out_at': '2025-05-01T00:00:00.000Z',
          },
        ],
        'responses': [
          {
            'id': 'resp-1',
            'org_foster_parent_id': 'fp-1',
            'response': 'can_help',
            'message': 'Available',
            'earliest_availability': '2025-06-05',
            'responded_at': '2025-06-02T12:00:00.000Z',
          },
        ],
        'target_count': 1,
        'response_summary': {'pending': 0, 'can_help': 1, 'cannot_help': 0},
      });

      expect(request.id, 'fr-1');
      expect(request.isSent, isTrue);
      expect(request.pets.single.petName, 'Bella');
      expect(request.targets.single.displayName, 'Alex');
      expect(request.responses.single.response, FosterResponseType.canHelp);
      expect(request.responses.single.isPending, isFalse);
      expect(request.responseSummary.canHelp, 1);
    });

    test('draft request defaults empty collections', () {
      final request = FosterRequest.fromJson({
        'id': 'fr-2',
        'organization_id': 'org-1',
        'message': '',
        'status': 'draft',
      });

      expect(request.isDraft, isTrue);
      expect(request.pets, isEmpty);
      expect(request.petIds, isEmpty);
      expect(request.targetCount, 0);
    });
  });
}
