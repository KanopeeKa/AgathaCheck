import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/care_item_occurrence_status_pill.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/detail/care_item_pet_context_tile.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Split identity: care type (left) + this occurrence (right) — D-OSM-002.
class OccurrenceIdentityCard extends ConsumerWidget {
  const OccurrenceIdentityCard({
    super.key,
    required this.detail,
    required this.onOpenCareDetails,
  });

  final OccurrenceDetail detail;
  final VoidCallback onOpenCareDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final item = detail.item;
    final occ = detail.occurrence;
    final schedule = detail.schedule;
    final petAsync = ref.watch(petByIdProvider(item.petId));
    final finished = _isFinished(item, schedule);
    final paused = schedule?.status == 'paused' || item.status == 'paused';
    final family = CareFamilyWire.fromWire(item.careFamily) ?? CareFamily.other;
    final familyLabel = careFamilyLabel(l, family);
    final recurring = _isRecurring(schedule);
    final scheduleSemantics = recurring
        ? l.occurrenceScheduleRecurring
        : l.occurrenceSchedulePlannedDate;
    final scheduleIcon = recurring ? Icons.autorenew : Icons.event_outlined;
    final pill = occurrenceStatusPillStyle(l, occ);
    final overdueDays = _daysOverdue(occ, item.asOf.date);

    return Semantics(
      identifier: 'occurrence_identity_card',
      container: true,
      child: CareItemModule(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Column(
                children: [
                  CareFamilyIcon.forWire(
                    type: null,
                    careFamily: item.careFamily,
                    showChip: false,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    familyLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: scheduleSemantics,
                    excludeSemantics: true,
                    child: Icon(
                      scheduleIcon,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatWhen(context, l, occ),
                    key: const Key('occurrence_scheduled_when'),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CareItemOccurrenceStatusPill(
                        key: const Key('occurrence_status'),
                        pill: pill,
                      ),
                      if (overdueDays != null)
                        Text(
                          l.occurrenceDaysOverdue(overdueDays),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  petAsync.when(
                    loading: () => const SizedBox(
                      height: 40,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (pet) =>
                        pet == null ? const SizedBox.shrink() : CareItemPetContextTile(pet: pet),
                  ),
                  if (finished || paused) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (finished)
                          CareItemStatusPill(
                            label: l.careItemStatusFinished,
                            tone: CareItemStatusTone.neutral,
                          ),
                        if (paused && !finished)
                          CareItemStatusPill(
                            label: l.careItemPausedStatus,
                            tone: CareItemStatusTone.neutral,
                          ),
                      ],
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      identifier: 'occurrence_open_care_details',
                      button: true,
                      label: l.occurrenceOpenCareDetails,
                      child: TextButton(
                        key: const Key('occurrence_open_care_details'),
                        onPressed: onOpenCareDetails,
                        child: ExcludeSemantics(
                          child: Text(l.occurrenceOpenCareDetails),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isFinished(CareItemSummary item, CareItemSchedule? schedule) {
    if (item.status == 'completed') return true;
    return schedule?.status == 'completed';
  }

  bool _isRecurring(CareItemSchedule? schedule) {
    if (schedule == null) return false;
    return schedule.intervalDays != null || schedule.repeatsDailyOrMore;
  }

  int? _daysOverdue(CareOccurrence occ, DateTime asOfDate) {
    if (occ.status != CareOccurrenceStatus.overdue) return null;
    final scheduled = DateTime(occ.date.year, occ.date.month, occ.date.day);
    final asOf = DateTime(asOfDate.year, asOfDate.month, asOfDate.day);
    final days = asOf.difference(scheduled).inDays;
    return days > 0 ? days : null;
  }

  String _formatWhen(BuildContext context, AppLocalizations l, CareOccurrence occ) {
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMd(locale).format(occ.date);
    final time = occ.time;
    if (time == null || time.isEmpty) return dateStr;
    final parts = time.split(':');
    if (parts.length < 2) return l.occurrenceDateAtTime(dateStr, time);
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final formattedTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));
    return l.occurrenceDateAtTime(dateStr, formattedTime);
  }
}
