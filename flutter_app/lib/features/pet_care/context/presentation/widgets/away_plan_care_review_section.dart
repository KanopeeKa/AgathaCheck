import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import '../../domain/entities/care_period_coverage.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/care_item_detail_with_absence_refresh.dart';

/// Care-item review queue for one pet on a saved away plan (D-004…D-009).
class AwayPlanCareReviewSection extends ConsumerStatefulWidget {
  const AwayPlanCareReviewSection({
    super.key,
    required this.absenceId,
    required this.petId,
    required this.reviewQueue,
  });

  final String absenceId;
  final String petId;
  final List<CareReviewQueueItem> reviewQueue;

  @override
  ConsumerState<AwayPlanCareReviewSection> createState() =>
      _AwayPlanCareReviewSectionState();
}

class _AwayPlanCareReviewSectionState
    extends ConsumerState<AwayPlanCareReviewSection> {
  bool _bulkMode = false;
  final Set<String> _selectedEntryIds = {};
  bool _bulkBusy = false;

  @override
  Widget build(BuildContext context) {
    if (widget.reviewQueue.isEmpty) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final allSelected =
        _selectedEntryIds.length == widget.reviewQueue.length &&
        widget.reviewQueue.isNotEmpty;
    final selectedEligible = widget.reviewQueue
        .where(
          (item) =>
              _selectedEntryIds.contains(item.healthEntryId) &&
              item.bulkKeepCarerEligible,
        )
        .toList();
    final canBulkKeep = _bulkMode &&
        selectedEligible.isNotEmpty &&
        selectedEligible.length == _selectedEntryIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                identifier: 'away_plan_review_section_title',
                child: Text(
                  l.careContextAwayReviewSectionTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
            TextButton(
              key: const Key('away_plan_review_bulk_toggle'),
              onPressed: () => setState(() {
                _bulkMode = !_bulkMode;
                if (!_bulkMode) {
                  _selectedEntryIds.clear();
                }
              }),
              child: Text(
                _bulkMode ? l.cancel : l.careContextAwayReviewBulkMode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.reviewQueue.map(
          (item) => _ReviewCard(
            petId: widget.petId,
            item: item,
            bulkMode: _bulkMode,
            selected: _selectedEntryIds.contains(item.healthEntryId),
            onSelected: (selected) => setState(() {
              if (selected) {
                _selectedEntryIds.add(item.healthEntryId);
              } else {
                _selectedEntryIds.remove(item.healthEntryId);
              }
            }),
          ),
        ),
        if (_bulkMode && _selectedEntryIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: allSelected
                    ? () => setState(() => _selectedEntryIds.clear())
                    : () => setState(() {
                        _selectedEntryIds
                          ..clear()
                          ..addAll(
                            widget.reviewQueue.map((e) => e.healthEntryId),
                          );
                      }),
                child: Text(
                  allSelected
                      ? l.careContextAwayReviewBulkClear
                      : l.careContextAwayReviewBulkSelectAll,
                ),
              ),
              FilledButton(
                key: const Key('away_plan_review_bulk_keep_carer'),
                onPressed: !canBulkKeep || _bulkBusy
                    ? null
                    : () => _bulkKeepWithCarer(selectedEligible),
                child: Text(l.careContextAwayReviewBulkKeepCarer),
              ),
            ],
          ),
          if (!canBulkKeep && _selectedEntryIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.careContextAwayReviewBulkKeepCarerDisabled,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _bulkKeepWithCarer(List<CareReviewQueueItem> items) async {
    if (_bulkBusy) return;
    setState(() => _bulkBusy = true);
    final l = AppLocalizations.of(context)!;
    final remote = ref.read(healthAbsenceContextRemoteProvider);
    try {
      for (final item in items) {
        await remote.saveResolution(
          absenceId: widget.absenceId,
          healthEntryId: item.healthEntryId,
          decision: 'keep_date',
        );
      }
      invalidateCareItemDetailWithAbsence(
        ref,
        items.first.healthEntryId,
        absenceId: widget.absenceId,
      );
      if (mounted) {
        setState(() {
          _bulkMode = false;
          _selectedEntryIds.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careCommandFailed)));
      }
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.petId,
    required this.item,
    required this.bulkMode,
    required this.selected,
    required this.onSelected,
  });

  final String petId;
  final CareReviewQueueItem item;
  final bool bulkMode;
  final bool selected;
  final ValueChanged<bool> onSelected;

  static const _kMinTouchTarget = 48.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    void openCare() {
      openPetEventView(context, petId: petId, entryId: item.healthEntryId);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bulkMode)
              Checkbox(
                key: Key('away_plan_review_select_${item.healthEntryId}'),
                value: selected,
                onChanged: (value) => onSelected(value == true),
              ),
            CareFamilyIcon.forWire(
              type: item.type,
              careFamily: item.careFamily,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: theme.textTheme.titleSmall),
                  Text(
                    l.careContextAwayReviewImpactedDates(item.impactedDateCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: Key('away_plan_review_dates_${item.healthEntryId}'),
                      onPressed: openCare,
                      child: Text(l.careContextAwayReviewDatesAction),
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
}
