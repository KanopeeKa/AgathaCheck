import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_care/context/presentation/providers/care_context_providers.dart';
import 'care_item_absence_providers.dart';
import 'health_providers.dart';
import 'occurrence_providers.dart';
import 'pet_event_view_providers.dart';

/// Invalidates occurrence and detail providers (no canonical store refresh).
void invalidateCareScheduleProviders(
  dynamic ref,
  String entryId, {
  String? absenceId,
}) {
  ref.invalidate(entryOccurrencesProvider(entryId));
  ref.invalidate(entryPastOccurrencesProvider(entryId));
  ref.invalidate(entryHistoryProvider(entryId));
  ref.invalidate(careItemAbsenceContextProvider(entryId));
  ref.invalidate(petHealthEntryByIdProvider);
  if (absenceId != null && absenceId.isNotEmpty) {
    ref.invalidate(absenceCarePlanProvider(absenceId));
  }
  ref.invalidate(carePeriodCoverageProvider);
}

/// Invalidates care item detail surfaces after occurrence or absence actions.
void invalidateCareItemDetailData(
  WidgetRef ref,
  String entryId, {
  String? absenceId,
}) {
  invalidateCareScheduleProviders(ref, entryId, absenceId: absenceId);
  ref.read(healthEntriesNotifierProvider.notifier).refresh();
}
