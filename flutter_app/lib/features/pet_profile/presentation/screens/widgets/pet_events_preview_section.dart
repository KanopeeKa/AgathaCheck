import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../experience/presentation/screens/pet_care/pet_care_upcoming_events_section.dart';
import '../../../../experience/presentation/widgets/pet_care_preview/pet_care_preview_optimistic.dart';
import '../../../../experience/presentation/widgets/pet_care_dashboard_section_header.dart';
import '../../../../experience/presentation/widgets/pet_care_illustrated_empty_state.dart';
import '../../../../experience/presentation/widgets/pet_care_operations_desk_layout.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/presentation/widgets/care_event_row_context.dart';
import '../../../domain/entities/pet.dart';
import '../../widgets/pet_list/home_event_actions.dart';

/// Pet-scoped due/overdue care preview — dashboard look and behaviour.
class PetEventsPreviewSection extends ConsumerStatefulWidget {
  const PetEventsPreviewSection({
    super.key,
    required this.petId,
    required this.pet,
  });

  final String petId;
  final Pet pet;

  @override
  ConsumerState<PetEventsPreviewSection> createState() =>
      _PetEventsPreviewSectionState();
}

class _PetEventsPreviewSectionState
    extends ConsumerState<PetEventsPreviewSection> {
  final Map<String, PetCareCareOptimisticCompletion> _completed = {};

  Future<void> _onMarkDone(HealthEntry entry, int previewIndex) async {
    final result = await HomeEventActions.showCompletionSheet(context);
    if (result == null || !mounted) return;

    setState(() {
      _completed[entry.id] = PetCareCareOptimisticCompletion(
        entry: entry,
        previewIndex: previewIndex,
      );
    });

    try {
      await HomeEventActions.commitCompletion(context, ref, entry, result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _completed.remove(entry.id));
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.careCompletionFailed)));
    }
  }

  Future<void> _onUndo(HealthEntry entry) async {
    try {
      await HomeEventActions.undoCompletion(context, ref, entry);
    } catch (_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.undoCompleteFailed)));
      return;
    }
    if (!mounted) return;
    setState(() => _completed.remove(entry.id));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(petHealthEntriesByIdProvider(widget.petId));
    final previewLimit = PetCareUpcomingEventsSection.previewLimit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: entriesAsync.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PetCareDashboardSectionHeader(title: l.careForPet(widget.pet.name)),
            const SizedBox(height: 10),
            const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ],
        ),
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PetCareDashboardSectionHeader(title: l.careForPet(widget.pet.name)),
            const SizedBox(height: 10),
            PetCareDeskSectionCard(
              tint: AppColorTokens.guardianLight,
              child: Text(
                l.errorLoadingEntries(error.toString()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
        data: (entries) {
          final dueEntries = entries.where(isEntryDueOrOverdue).toList()
            ..sort((a, b) {
              final ad = a.nextDueDate ?? DateTime(2100);
              final bd = b.nextDueDate ?? DateTime(2100);
              return ad.compareTo(bd);
            });

          final showAllCare = dueEntries.length > previewLimit;
          final items = buildPetCareMobilePreview(
            dueEntries: dueEntries,
            completed: _completed,
            previewLimit: previewLimit,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PetCareDashboardSectionHeader(
                title: l.careForPet(widget.pet.name),
              ),
              const SizedBox(height: 10),
              PetCareDeskSectionCard(
                key: const Key('pet_detail_care_section'),
                tint: AppColorTokens.guardianLight,
                child: items.isEmpty
                    ? PetCareIllustratedEmptyState(
                        key: const Key('pet_detail_empty_care'),
                        title: l.petCareEmptyCareClearTitle,
                        body: l.homeNoDueEvents,
                        actionLabel: l.allCare,
                        actionIcon: Icons.calendar_month_outlined,
                        onAction: () =>
                            context.push('/pet/${widget.petId}/events'),
                      )
                    : PetCareCarePreviewEventList(
                        items: items,
                        petMap: {widget.pet.id: widget.pet},
                        onMarkDone: _onMarkDone,
                        onUndo: _onUndo,
                        onView: (entry) =>
                            HomeEventActions.viewEntry(context, entry),
                        rowContext: CareEventRowContext.pet,
                      ),
              ),
              if (showAllCare)
                PetCareDashboardSectionLink(
                  linkKey: const Key('pet_detail_care_view_all'),
                  label: l.allCare,
                  onPressed: () => context.push('/pet/${widget.petId}/events'),
                ),
            ],
          );
        },
      ),
    );
  }
}
