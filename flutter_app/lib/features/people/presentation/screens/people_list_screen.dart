import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../domain/entities/people_contact.dart';
import '../providers/people_providers.dart';
class PeopleListScreen extends ConsumerWidget {
  const PeopleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final asyncContacts = ref.watch(peopleContactsProvider);

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: '/account/people',
      screenTitle: l.peoplePageTitle,
      child: asyncContacts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.peopleListLoadError)),
        data: (contacts) {
          final pros = contacts.where((c) => c.isProfessional).toList();
          final prosIds = pros.map((c) => c.id).toSet();
          final carers = contacts.where((c) => !prosIds.contains(c.id)).toList();
          return RefreshIndicator(
            onRefresh: () => ref.read(peopleContactsProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(
                  title: l.peopleTrustedCarersSection,
                  contacts: carers,
                  empty: l.peopleEmptyCarers,
                ),
                const SizedBox(height: 24),
                _Section(
                  title: l.peopleProfessionalsSection,
                  contacts: pros,
                  empty: l.peopleEmptyProfessionals,
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/account/people/new');
          if (created == true) {
            ref.invalidate(peopleContactsProvider);
          }
        },
        icon: const Icon(Icons.person_add_outlined),
        label: Text(l.peopleAddPerson),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.contacts,
    required this.empty,
  });

  final String title;
  final List<PeopleContact> contacts;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (contacts.isEmpty)
          Text(empty, style: Theme.of(context).textTheme.bodyMedium)
        else
          ...contacts.map(
            (c) => ListTile(
              key: Key('people_contact_${c.id}'),
              title: Text(c.name),
              subtitle: Text(
                c.roles.isEmpty ? c.kind : c.roles.join(' · '),
              ),
              leading: CircleAvatar(
                child: Text(
                  c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
