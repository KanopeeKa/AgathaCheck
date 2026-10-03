import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../care_item/care_item.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../pet_care/presentation/widgets/care_agenda/care_agenda_collection.dart';
import '../../../../pet_care/presentation/widgets/care_agenda/care_agenda_inset_items.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_collection_inset_list.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../widgets/pet_care_dashboard_section_header.dart';
import '../../widgets/pet_care_illustrated_empty_state.dart';

/// Guardian Care dashboard: the agenda for all pets (D-CIE-025) with the
/// orientation line (UIR-17). Rows change only after the server confirms
/// (UIR-2); the previous list stays visible while it reloads.
class PetCareUpcomingEventsSection extends ConsumerWidget {
  const PetCareUpcomingEventsSection({
    super.key,
    required this.pets,
    this.onAddEvent,
  });

  final List<Pet> pets;
  final VoidCallback? onAddEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);
    final petIds = pets.where((p) => !p.passedAway).map((p) => p.id).toSet();
    final entries = entriesAsync.valueOrNull
        ?.where((e) => petIds.contains(e.petId))
        .toList();
    final hasCare = entries != null && entries.isNotEmpty;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l.careEyebrow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PetCareDashboardSectionChrome(
            title: l.careEyebrow,
            linkLabel: hasCare ? l.allCare : null,
            linkKey: const Key('pet_care_dashboard_care_view_all'),
            onLinkPressed: hasCare ? () => context.go('/pc/events') : null,
          ),
          const SizedBox(height: 10),
          KeyedSubtree(
            key: const Key('pet_care_dashboard_care_section'),
            child: _body(context, ref, l, entriesAsync, entries),
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    AsyncValue<List<HealthEntry>> entriesAsync,
    List<HealthEntry>? entries,
  ) {
    if (entries == null) {
      if (entriesAsync.hasError) return _error(ref, l);
      return _collection(
        const SizedBox(
          height: 56,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    if (entries.isEmpty) {
      return PetCareIllustratedEmptyState(
        key: const Key('pet_care_dashboard_empty_care'),
        assetPath: 'assets/dashboard/pet-care-empty-care.png',
        title: l.petCareEmptyCareTitle,
        body: l.petCareEmptyCareBody,
        actionLabel: l.addAnEvent,
        actionKey: const Key('pet_care_dashboard_empty_care_action'),
        onAction: onAddEvent,
      );
    }
    return CareAgendaCollection(
      key: const Key('pet_care_dashboard_care_block'),
      entries: entries,
      source: CareCommandSource.dashboard,
      petNames: {for (final pet in pets) pet.id: pet.name},
      empty: PetCareIllustratedEmptyState(
        key: const Key('pet_care_dashboard_empty_care_clear'),
        title: l.petCareEmptyCareClearTitle,
        body: l.noCareDue,
        actionLabel: l.allCare,
        actionIcon: Icons.calendar_month_outlined,
        onAction: () => context.go('/pc/events'),
      ),
      header: (agenda) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Semantics(
          identifier: 'care_agenda_orientation',
          label: careAgendaOrientation(l, agenda),
          child: ExcludeSemantics(
            child: Text(
              careAgendaOrientation(l, agenda),
              key: const Key('care_agenda_orientation'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _collection(Widget child) => CareCollectionInsetList(
    key: const Key('pet_care_dashboard_care_block'),
    children: [CareCollectionInsetItem(child: child)],
  );

  Widget _error(WidgetRef ref, AppLocalizations l) => _collection(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: AppColorTokens.danger),
        const SizedBox(height: 8),
        Text(l.careLoadError),
        TextButton.icon(
          onPressed: () =>
              ref.read(healthEntriesNotifierProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l.retry),
        ),
      ],
    ),
  );
}
