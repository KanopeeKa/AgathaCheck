import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/care_item_occurrence_status_pill.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'occurrence_reschedule.dart';
import 'occurrence_schedule_action_bar.dart';

/// Split identity: care family + pet (left) + occurrence context (right).
class OccurrenceIdentityCard extends ConsumerWidget {
  const OccurrenceIdentityCard({
    super.key,
    required this.detail,
    required this.onOpenCareDetails,
    this.scheduleActionsBusy = false,
    this.onChangeDate,
    this.onSkip,
  });

  final OccurrenceDetail detail;
  final VoidCallback onOpenCareDetails;
  final bool scheduleActionsBusy;
  final VoidCallback? onChangeDate;
  final VoidCallback? onSkip;

  static const double _familyChipSize = 52;
  static const double _petAvatarSize = 48;
  static const double _leftRailWidth = 100;

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
    final showScheduleActions = occ.isOpen && onChangeDate != null && onSkip != null;

    return Semantics(
      identifier: 'occurrence_identity_card',
      container: true,
      child: CareItemModule(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _leftRailWidth,
              child: Column(
                children: [
                  CareFamilyIcon(
                    family: family,
                    showChip: true,
                    chipSize: _familyChipSize,
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
                      size: 24,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  petAsync.when(
                    loading: () => const SizedBox(
                      width: _petAvatarSize,
                      height: _petAvatarSize,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (pet) => pet == null
                        ? const SizedBox.shrink()
                        : _PetRailAvatar(pet: pet),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatWhen(context, l, occ),
                    key: const Key('occurrence_scheduled_when'),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: CareItemOccurrenceStatusPill(
                            key: const Key('occurrence_status'),
                            pill: pill,
                          ),
                        ),
                      ),
                      if (overdueDays != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l.occurrenceDaysOverdue(overdueDays),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (showScheduleActions) ...[
                    const SizedBox(height: 12),
                    OccurrenceScheduleActionBar(
                      busy: scheduleActionsBusy,
                      showChangeDate: occurrenceShowsReschedule(detail),
                      onChangeDate: onChangeDate,
                      onSkip: onSkip,
                    ),
                  ],
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

  String _formatWhen(
    BuildContext context,
    AppLocalizations l,
    CareOccurrence occ,
  ) {
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

class _PetRailAvatar extends ConsumerWidget {
  const _PetRailAvatar({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);

    return Semantics(
      button: true,
      label: pet.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openPetDetail(context, pet.id),
          customBorder: const CircleBorder(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: OccurrenceIdentityCard._petAvatarSize,
                height: OccurrenceIdentityCard._petAvatarSize,
                child: ClipOval(
                  child: buildPetPhotoOrPlaceholder(
                    photoPath: pet.photoPath,
                    apiBaseUrl: apiBaseUrl,
                    fit: BoxFit.cover,
                    semanticLabel: 'Photo of ${pet.name}',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pet.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
