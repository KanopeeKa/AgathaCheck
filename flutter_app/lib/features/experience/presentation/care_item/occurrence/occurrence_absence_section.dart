import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../care_item_detail_with_absence_refresh.dart';

/// Away context for one open occurrence (D-OCC-014, D-OCC-015).
class OccurrenceAbsenceSection extends ConsumerWidget {
  const OccurrenceAbsenceSection({
    super.key,
    required this.entryId,
    required this.detail,
    required this.onChanged,
  });

  final String entryId;
  final OccurrenceDetail detail;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occ = detail.occurrence;
    if (!occ.isOpen) return const SizedBox.shrink();

    final wireDate = wireDateForOccurrence(occ.date);
    final asyncContext = ref.watch(careItemAbsenceContextProvider(entryId));

    return asyncContext.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (model) {
        HealthEntryAbsenceSlice? slice;
        for (final s in model.absences) {
          if (s.affected && absenceSliceConflictsOnDate(s, wireDate)) {
            slice = s;
            break;
          }
        }
        if (slice == null) return const SizedBox.shrink();
        return _Body(slice: slice, entryId: entryId, onChanged: onChanged);
      },
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    required this.slice,
    required this.entryId,
    required this.onChanged,
  });

  final HealthEntryAbsenceSlice slice;
  final String entryId;
  final Future<void> Function() onChanged;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final slice = widget.slice;
    final away = slice.resolutionDecision == 'keep_date';
    final carer = slice.carerDisplayName();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.occurrenceAwaySectionTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.flight_takeoff_outlined,
              size: 18,
              color: AppColorTokens.awayContextAccent,
            ),
            const SizedBox(width: 8),
            Text(
              l.occurrenceAwayPresenceAway,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (away)
          Text(
            carer != null
                ? l.careCoverPlanResolvedNamed(carer)
                : l.careCoverPlanResolved,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          )
        else if (slice.needsAttention) ...[
          Text(_summaryLine(l, slice), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            l.occurrenceAwayKeepScopeExplainer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('occurrence_absence_keep'),
            onPressed: _busy ? null : _keepDate,
            child: Text(_keepLabel(l, slice)),
          ),
        ] else
          Text(_summaryLine(l, slice), style: theme.textTheme.bodyMedium),
      ],
    );
  }

  String _keepLabel(AppLocalizations l, HealthEntryAbsenceSlice slice) {
    final carer = slice.carerDisplayName();
    if (carer != null) {
      return l.careItemAbsenceKeepWithCarer(carer);
    }
    return l.careItemAbsenceKeepDuringAbsence;
  }

  String _summaryLine(AppLocalizations l, HealthEntryAbsenceSlice slice) {
    final start = parseCalendarDate(slice.startsOn);
    final end = parseCalendarDate(slice.endsOn);
    final range = start != null && end != null
        ? '${DateFormat.MMMd().format(start)}–${DateFormat.MMMd().format(end)}'
        : '${slice.startsOn}–${slice.endsOn}';
    switch (slice.uiState) {
      case 'resolved':
        return l.careItemAbsenceResolved;
      default:
        return '${l.careItemAbsenceNotReviewed} · $range';
    }
  }

  Future<void> _keepDate() async {
    if (_busy) return;
    setState(() => _busy = true);
    final slice = widget.slice;
    final l = AppLocalizations.of(context)!;
    try {
      final remote = ref.read(healthAbsenceContextRemoteProvider);
      final lookedAfter =
          slice.suggestedLookedAfterBy?.toApiPayload() ??
          slice.petCarer?.toApiPayload();
      await remote.saveResolution(
        absenceId: slice.plannedAbsenceId,
        healthEntryId: widget.entryId,
        decision: 'keep_date',
        lookedAfterBy: lookedAfter,
      );
      invalidateCareItemDetailWithAbsence(
        ref,
        widget.entryId,
        absenceId: slice.plannedAbsenceId,
      );
      await widget.onChanged();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careCommandFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
