import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_issue.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_issue_repository.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/care_schedule_controller.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_issue_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';

import '../../../../helpers/fakes.dart';
import '../providers/health_entries_test_support.dart';

class _FakeHealthIssueRepository implements HealthIssueRepository {
  final linkedPairs = <({String issueId, String entryId})>[];

  @override
  Future<void> linkEvent(String issueId, String entryId, String token) async {
    linkedPairs.add((issueId: issueId, entryId: entryId));
  }

  @override
  Future<List<HealthIssue>> getIssues(String petId, String token) async {
    return [
      HealthIssue(id: 'issue-1', petId: petId, title: 'Issue', eventIds: []),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('linkHealthIssue refreshes canonical health entries store', () async {
    final issueRepo = _FakeHealthIssueRepository();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        healthRepositoryProvider.overrideWithValue(
          _CareScheduleEntriesRepository(),
        ),
        healthIssueRepositoryProvider.overrideWithValue(issueRepo),
      ],
    );

    await container.read(healthEntriesNotifierProvider.future);
    final before = container.read(healthEntriesNotifierProvider).value!.length;

    final outcome = await container
        .read(careScheduleControllerProvider)
        .linkHealthIssue('pet-1', 'issue-1', 'e1');

    expect(outcome.committed, isTrue);
    expect(issueRepo.linkedPairs, hasLength(1));
    expect(
      container.read(healthEntriesNotifierProvider).value,
      hasLength(before),
    );
    container.dispose();
  });
}

class _CareScheduleEntriesRepository extends FakeHealthRepository {
  _CareScheduleEntriesRepository() : super(entries: [testHealthEntry('e1')]);
}
