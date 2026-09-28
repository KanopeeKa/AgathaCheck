import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../providers/people_providers.dart';

class PeopleDetailScreen extends ConsumerWidget {
  const PeopleDetailScreen({super.key, required this.personId, this.embedded = false});

  final String personId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final contact = ref.watch(peopleContactByIdProvider(personId));

    if (contact == null) {
      final body = Center(child: Text(l.peopleDetailNotFound));
      if (embedded) return body;
      return ExperienceShellScaffold(
        experience: AppExperience.petCare,
        currentLocation: '/pc/people/$personId',
        screenTitle: l.peoplePageTitle,
        child: body,
      );
    }

    final inactive = contact.inactiveAt != null;

    Widget content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                contact.name.isNotEmpty
                    ? contact.name.trim()[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (contact.roles.isNotEmpty)
                    Text(
                      contact.roles.join(' · '),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (inactive)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l.peopleStatusInactive,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (contact.phone != null && contact.phone!.isNotEmpty)
          _InfoRow(label: l.peoplePhoneLabel, value: contact.phone!),
        if (contact.email != null && contact.email!.isNotEmpty)
          _InfoRow(label: l.peopleEmailLabel, value: contact.email!),
        if (contact.privateNote.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l.peoplePrivateNoteLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(contact.privateNote),
        ],
      ],
    );

    if (embedded) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('/pc/people/$personId/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l.peopleEditPerson),
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: '/pc/people/$personId',
      screenTitle: contact.name,
      child: content,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/pc/people/$personId/edit'),
        icon: const Icon(Icons.edit_outlined),
        label: Text(l.peopleEditPerson),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
