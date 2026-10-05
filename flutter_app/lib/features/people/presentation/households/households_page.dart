import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/household.dart';
import 'household_create_flow.dart';
import 'household_tier_labels.dart';

class HouseholdsPage extends ConsumerWidget {
  const HouseholdsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final asyncHouseholds = ref.watch(peopleHouseholdsProvider);

    final body = asyncHouseholds.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l.peopleListLoadError)),
      data: (households) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(peopleHouseholdsProvider);
          await ref.read(rosterProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (households.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l.householdsEmpty,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            for (final household in households)
              _HouseholdListTile(household: household),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('households_create'),
              onPressed: () async {
                final id = await showCreateHouseholdFlow(context);
                if (id != null && context.mounted) {
                  final router = GoRouter.maybeOf(context);
                  if (router != null) {
                    context.go('/pc/people/households/$id');
                  }
                }
              },
              icon: const Icon(Icons.home_work_outlined),
              label: Text(l.householdCreate),
            ),
          ],
        ),
      ),
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.householdsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/pc/people'),
        ),
      ),
      body: body,
    );
  }
}

class _HouseholdListTile extends StatelessWidget {
  const _HouseholdListTile({required this.household});

  final Household household;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final subtitle = householdTierLabel(
      l,
      household.myTier,
      organiser: household.myIsOrganiser,
    );
    return Card(
      child: ListTile(
        key: Key('household_card_${household.id}'),
        title: Text(household.name),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/pc/people/households/${household.id}'),
      ),
    );
  }
}
