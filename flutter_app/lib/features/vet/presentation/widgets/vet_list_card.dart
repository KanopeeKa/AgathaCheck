import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vet.dart';
import '../utils/vet_accent.dart';

class VetListCard extends StatelessWidget {
  const VetListCard({
    super.key,
    required this.vet,
    required this.linkedPetNames,
    required this.onEdit,
    this.organizationName,
  });

  final Vet vet;
  final List<String> linkedPetNames;
  final VoidCallback onEdit;
  final String? organizationName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final accent = resolveVetAccent(
      context,
      organizationId: vet.organizationId,
    );
    final town = vetTownLabel(vet.address);
    final subtitleParts = <String>[
      if (town.isNotEmpty) town,
      if (vet.phone.isNotEmpty) vet.phone,
      if (linkedPetNames.isNotEmpty) 'Pets: ${linkedPetNames.join(', ')}',
      if (organizationName != null && organizationName!.isNotEmpty)
        organizationName!,
    ];

    return Card(
      key: Key('vet_card_${vet.name}'),
      margin: const EdgeInsets.only(bottom: 8),
      color: accent.surface,
      child: Semantics(
        label:
            'Veterinarian: ${vet.name}${vet.phone.isNotEmpty ? ', Phone: ${vet.phone}' : ''}${vet.address.isNotEmpty ? ', Address: ${vet.address}' : ''}',
        explicitChildNodes: true,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: accent.primary.withAlpha(60),
            child: Icon(Icons.local_hospital, color: accent.primary),
          ),
          title: Text(vet.name, style: theme.textTheme.titleMedium),
          subtitle: subtitleParts.isEmpty
              ? null
              : Text(subtitleParts.join(' \u2022 ')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (vet.phone.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.phone_outlined),
                  tooltip: l.phone,
                  onPressed: () => _callVet(vet.phone),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l.edit,
                onPressed: onEdit,
              ),
            ],
          ),
          onTap: onEdit,
        ),
      ),
    );
  }

  Future<void> _callVet(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
