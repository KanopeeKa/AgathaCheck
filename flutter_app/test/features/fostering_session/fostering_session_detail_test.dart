import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/fostering_session/domain/entities/fostering_session_detail.dart';
import 'package:pet_profile_app/features/fostering_session/domain/entities/session_viewer_context.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_session_status.dart';

void main() {
  test('FosteringSessionDetail.fromJson parses viewer and checklist', () {
    final detail = FosteringSessionDetail.fromJson({
      'id': 'placement-1',
      'organization_id': 'org-1',
      'pet_id': 'pet-1',
      'foster_user_id': 'user-1',
      'status': 'pending',
      'session_status': FosterSessionStatus.preparation,
      'pet_name': 'Max',
      'foster_name': 'Jane',
      'viewer': {
        'role': SessionViewerRole.shelterOperator,
        'allowed_actions': [
          SessionAction.transitionReadyToStart,
          SessionAction.registerExport,
        ],
      },
      'pet': {'id': 'pet-1', 'name': 'Max', 'species': 'dog'},
      'organization': {'id': 'org-1', 'name': 'Test Org'},
      'counterparty': {
        'kind': 'foster',
        'id': 'user-1',
        'display_name': 'Jane',
      },
      'checklist': {
        'items': [
          {
            'key': 'foster_contract_signed',
            'label': 'Contract signed',
            'completed': false,
            'is_required': true,
          },
        ],
      },
      'flagged_for_admin_review': true,
    });

    expect(detail.placement.id, 'placement-1');
    expect(detail.viewer.role, SessionViewerRole.shelterOperator);
    expect(detail.can(SessionAction.registerExport), isTrue);
    expect(detail.can(SessionAction.requestEnd), isFalse);
    expect(detail.checklist.items, hasLength(1));
    expect(detail.flaggedForAdminReview, isTrue);
    expect(detail.pet.name, 'Max');
  });
}
