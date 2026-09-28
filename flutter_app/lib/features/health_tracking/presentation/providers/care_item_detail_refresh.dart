import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/pet_event_view_providers.dart';
import '../widgets/reschedule_occurrence_flow.dart';
import 'care_item_absence_providers.dart';
import 'health_providers.dart';
import 'occurrence_providers.dart';

/// Invalidates care item detail surfaces after occurrence or absence actions.
void invalidateCareItemDetailData(
  WidgetRef ref,
  String entryId, {
  String? absenceId,
}) {
  ref.invalidate(entryOccurrencesProvider(entryId));
  ref.invalidate(entryPastOccurrencesProvider(entryId));
  ref.invalidate(entryHistoryProvider(entryId));
  ref.invalidate(careItemAbsenceContextProvider(entryId));
  ref.invalidate(petHealthEntryByIdProvider);
  if (absenceId != null && absenceId.isNotEmpty) {
    RescheduleOccurrenceFlow.invalidateAfterReschedule(
      ref,
      entryId,
      absenceId: absenceId,
    );
  }
  ref.read(healthEntriesNotifierProvider.notifier).refresh();
}
