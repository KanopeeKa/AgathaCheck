import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../domain/entities/family_event.dart';
import 'org_provider_deps.dart';

class FamilyEventsNotifier
    extends FamilyAsyncNotifier<List<FamilyEvent>, String> {
  @override
  Future<List<FamilyEvent>> build(String petId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    try {
      final data = await repo.getFamilyEvents(token, petId);
      return data.map((e) => FamilyEvent.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> createEvent({
    required String? assignedToUserId,
    required DateTime fromDate,
    DateTime? toDate,
    String notes = '',
  }) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.createFamilyEvent(token, arg, {
      if (assignedToUserId != null) 'assigned_to_user_id': assignedToUserId,
      'from_date': toCalendarDateString(fromDate),
      if (toDate != null) 'to_date': toCalendarDateString(toDate),
      'notes': notes,
    });
    ref.invalidateSelf();
  }

  Future<void> updateEvent(
    String eventId, {
    required String? assignedToUserId,
    required DateTime fromDate,
    DateTime? toDate,
    String notes = '',
  }) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.updateFamilyEvent(token, arg, eventId, {
      'assigned_to_user_id': assignedToUserId,
      'from_date': toCalendarDateString(fromDate),
      if (toDate != null) 'to_date': toCalendarDateString(toDate),
      'notes': notes,
    });
    ref.invalidateSelf();
  }

  Future<void> deleteEvent(String eventId) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.deleteFamilyEvent(token, arg, eventId);
    ref.invalidateSelf();
  }
}

final familyEventsProvider =
    AsyncNotifierProvider.family<
      FamilyEventsNotifier,
      List<FamilyEvent>,
      String
    >(FamilyEventsNotifier.new);
