import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/vet_providers.dart';
import '../utils/vet_accent.dart';

/// Display-first vet detail screen (D24). Edit is a separate route.
class VetDetailScreen extends ConsumerWidget {
  const VetDetailScreen({
    super.key,
    required this.vetId,
    this.listPath = '/g/vets',
  });

  final String vetId;
  final String listPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final vetListAsync = ref.watch(vetListProvider);
    final pets = ref.watch(petListProvider).valueOrNull ?? [];

    return vetListAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (vets) {
        final vet = vets.where((v) => v.id == vetId).firstOrNull;
        if (vet == null) {
          return Center(child: Text(l.vetNotFound));
        }

        final linkedPets = pets.where((p) => p.vetId == vet.id).toList();
        final accent = resolveVetAccent(
          context,
          organizationId: vet.organizationId,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: accent.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: accent.primary.withAlpha(60),
                            child: Icon(
                              Icons.local_hospital,
                              color: accent.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              vet.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (vet.address.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _DetailRow(
                          icon: Icons.location_on_outlined,
                          label: l.address,
                          value: vet.address,
                        ),
                      ],
                      if (vet.phone.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.phone_outlined,
                          label: l.phone,
                          value: vet.phone,
                          action: IconButton(
                            icon: const Icon(Icons.call),
                            tooltip: l.phone,
                            onPressed: () => _launchTel(vet.phone),
                          ),
                        ),
                      ],
                      if (vet.email.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.email_outlined,
                          label: l.email,
                          value: vet.email,
                          action: IconButton(
                            icon: const Icon(Icons.mail_outline),
                            tooltip: l.email,
                            onPressed: () => _launchMail(vet.email),
                          ),
                        ),
                      ],
                      if (vet.website.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.language,
                          label: l.website,
                          value: vet.website,
                        ),
                      ],
                      if (vet.notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.notes,
                          label: l.notes,
                          value: vet.notes,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (linkedPets.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l.vetLinkedPets,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...linkedPets.map(
                  (pet) => ListTile(
                    leading: const Icon(Icons.pets),
                    title: Text(pet.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/pet/${pet.id}'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('$listPath/edit/$vetId'),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l.edit),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchTel(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchMail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.action,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
