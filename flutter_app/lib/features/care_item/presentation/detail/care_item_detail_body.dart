import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_care/presentation/widgets/care_surface/care_collection_inset_list.dart';
import '../../../pet_care/presentation/widgets/care_surface/care_item_module.dart';
import '../../../pet_care/presentation/widgets/care_surface/care_item_section_header.dart';
import '../../../pet_care/presentation/widgets/care_surface/care_surface_tokens.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/domain/entities/health_history_entry.dart';
import '../../../health_tracking/presentation/providers/care_item_absence_providers.dart';
import '../../../health_tracking/presentation/widgets/care_category_blocks/care_category_blocks_detail_section.dart';
import '../../../health_tracking/presentation/widgets/pet_event_documents_strip.dart';
import '../../../health_tracking/presentation/widgets/pet_event_lifecycle.dart';
import '../../../health_tracking/presentation/widgets/pet_event_past_iterations_section.dart';
import '../../../health_tracking/presentation/widgets/pet_event_past_occurrences_section.dart';
import '../../../health_tracking/presentation/widgets/pet_event_pet_card.dart';
import 'care_item_absence_section.dart';
import 'care_item_dates_section.dart';
import 'care_item_needs_attention_section.dart';
import 'care_item_established_section.dart';
import 'care_item_info_section.dart';
import 'care_item_schedule_section.dart';

/// Care Item detail body — module segmentation on warm canvas (mobile order).
class CareItemDetailBody extends ConsumerWidget {
  const CareItemDetailBody({
    super.key,
    required this.petId,
    required this.entry,
    required this.pet,
    required this.history,
    required this.isClosed,
    required this.isEstablished,
    required this.onSeeHistory,
  });

  final String petId;
  final HealthEntry entry;
  final Pet pet;
  final List<HealthHistoryEntry> history;
  final bool isClosed;
  final bool isEstablished;
  final VoidCallback onSeeHistory;

  static const _sectionGap = SizedBox(height: 16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = isClosed;
    final showNeedsAttention = !isClosed && !entry.isCompleted;
    final absenceContext = ref.watch(careItemAbsenceContextProvider(entry.id));
    final absenceBeforeSchedule = absenceContext.maybeWhen(
      data: (model) => model.absences.any((slice) => slice.needsAttention),
      orElse: () => false,
    );

    final petModule = CareItemModule(
      child: PetEventPetCard(pet: pet, embedded: true),
    );
    final schedule = entry.schedule;
    final needsSection = showNeedsAttention
        ? (schedule != null && !entry.isPaused
              ? CareItemNeedsAttentionSection(
                  entry: entry,
                  schedule: schedule,
                  muted: muted,
                )
              : CareItemDatesSection(entry: entry, muted: muted))
        : _ClosedNeedsAttentionModule(history: history, muted: muted);
    final absenceSection = CareItemAbsenceSection(entry: entry, muted: muted);
    final scheduleSection = CareItemScheduleSection(
      entry: entry,
      petId: petId,
      muted: muted,
    );
    final establishedSection = CareItemEstablishedSection(
      pet: pet,
      isEstablished: isEstablished,
    );
    final historyModule = _HistoryModule(
      entry: entry,
      history: history,
      isClosed: isClosed,
      muted: muted,
      onSeeHistory: onSeeHistory,
    );

    Widget sideScheduleAbsenceColumn() {
      if (absenceBeforeSchedule) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [absenceSection, _sectionGap, scheduleSection],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [scheduleSection, _sectionGap, absenceSection],
      );
    }

    return CareItemDetailCanvas(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layoutWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final wide = layoutWidth >= kCareItemTwoColumnBreakpoint;

          final content = wide
              ? Row(
                  key: const Key('care_item_detail_two_column'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          needsSection,
                          if (isEstablished) ...[
                            _sectionGap,
                            CareItemModule(child: establishedSection),
                          ],
                          _sectionGap,
                          historyModule,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          petModule,
                          _sectionGap,
                          sideScheduleAbsenceColumn(),
                          _sectionGap,
                          _DetailsModule(
                            entry: entry,
                            pet: pet,
                            petId: petId,
                            muted: muted,
                            isEstablished: isEstablished,
                            includeEstablished: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    petModule,
                    _sectionGap,
                    needsSection,
                    _sectionGap,
                    sideScheduleAbsenceColumn(),
                    _sectionGap,
                    _DetailsModule(
                      entry: entry,
                      pet: pet,
                      petId: petId,
                      muted: muted,
                      isEstablished: isEstablished,
                      includeEstablished: true,
                    ),
                    _sectionGap,
                    historyModule,
                  ],
                );

          return SingleChildScrollView(
            key: const Key('care_item_detail_body'),
            padding: const EdgeInsets.all(16),
            child: content,
          );
        },
      ),
    );
  }
}

class _DetailsModule extends StatelessWidget {
  const _DetailsModule({
    required this.entry,
    required this.pet,
    required this.petId,
    required this.muted,
    required this.isEstablished,
    required this.includeEstablished,
  });

  final HealthEntry entry;
  final Pet pet;
  final String petId;
  final bool muted;
  final bool isEstablished;
  final bool includeEstablished;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return CareItemModule(
      key: const Key('care_item_details_module'),
      semanticLabel: l.careItemDetailsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CareItemSectionHeader(
            title: l.careItemDetailsTitle,
            icon: Icons.article_outlined,
          ),
          const SizedBox(height: 12),
          CareCategoryBlocksDetailSection(entry: entry, pet: pet, muted: muted),
          CareItemInfoSection(entry: entry, muted: muted),
          if (includeEstablished)
            CareItemEstablishedSection(pet: pet, isEstablished: isEstablished),
          if (entry.healthIssueId != null &&
              (entry.healthIssueName?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            _HealthIssueLink(
              petId: petId,
              issueName: entry.healthIssueName!,
              muted: muted,
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryModule extends StatelessWidget {
  const _HistoryModule({
    required this.entry,
    required this.history,
    required this.isClosed,
    required this.muted,
    required this.onSeeHistory,
  });

  final HealthEntry entry;
  final List<HealthHistoryEntry> history;
  final bool isClosed;
  final bool muted;
  final VoidCallback onSeeHistory;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return CareItemModule(
      key: const Key('care_item_history_module'),
      semanticLabel: l.careItemHistoryTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CareItemSectionHeader(
            title: l.careItemHistoryTitle,
            icon: Icons.history,
          ),
          const SizedBox(height: 12),
          CareCollectionInsetList(
            semanticLabel: l.careItemHistoryTitle,
            children: [
              CareCollectionInsetItem(
                child: Padding(
                  padding: CareSurfaceTokens.collectionInsetRowPadding,
                  child: PetEventDocumentsStrip(entryId: entry.id),
                ),
              ),
              CareCollectionInsetItem(
                showDividerBefore: true,
                child: PetEventPastOccurrencesSection(
                  entryId: entry.id,
                  petId: entry.petId,
                  muted: muted,
                ),
              ),
              CareCollectionInsetItem(
                showDividerBefore: true,
                child: PetEventPastIterationsSection(
                  entry: entry,
                  history: history,
                  isClosed: isClosed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('care_item_see_history'),
            onPressed: onSeeHistory,
            icon: const Icon(Icons.history),
            label: Text(l.seeHistory),
          ),
        ],
      ),
    );
  }
}

class _ClosedNeedsAttentionModule extends StatelessWidget {
  const _ClosedNeedsAttentionModule({
    required this.history,
    required this.muted,
  });

  final List<HealthHistoryEntry> history;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final last = sortedHistoryDesc(history).firstOrNull;

    return CareItemModule(
      key: const Key('care_item_needs_attention_section'),
      semanticLabel: l.careItemNeedsAttentionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CareItemSectionHeader(
            title: l.careItemNeedsAttentionTitle,
            icon: Icons.flag_outlined,
          ),
          const SizedBox(height: 12),
          if (last == null)
            Text(
              l.noHistoryYet,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Text(
              last.isSkipped
                  ? l.occurrenceSkipped
                  : last.completedOn != null
                  ? l.doneOn(DateFormat.yMMMd().format(last.completedOn!))
                  : l.notSet,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _HealthIssueLink extends StatelessWidget {
  const _HealthIssueLink({
    required this.petId,
    required this.issueName,
    required this.muted,
  });

  final String petId;
  final String issueName;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.relatesToHealthIssue,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: muted ? colorScheme.onSurfaceVariant : null,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          key: const Key('care_item_health_issue_link'),
          onTap: muted ? null : () => context.push('/pet/$petId/health-issues'),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  issueName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: muted
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
