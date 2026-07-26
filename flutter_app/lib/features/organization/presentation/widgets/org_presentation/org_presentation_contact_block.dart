import 'package:flutter/material.dart';

import '../../../domain/entities/organization.dart';

class OrgPresentationContactBlock extends StatelessWidget {
  const OrgPresentationContactBlock({
    super.key,
    required this.org,
    required this.title,
  });

  final Organization org;
  final String title;

  @override
  Widget build(BuildContext context) {
    final hasContact =
        org.email.isNotEmpty ||
        org.phone.isNotEmpty ||
        org.address.isNotEmpty ||
        org.website.isNotEmpty ||
        org.town.isNotEmpty;

    if (!hasContact) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (org.email.isNotEmpty)
              _ContactRow(icon: Icons.email, text: org.email),
            if (org.phone.isNotEmpty)
              _ContactRow(icon: Icons.phone, text: org.phone),
            if (org.address.isNotEmpty)
              _ContactRow(icon: Icons.location_on, text: org.address),
            if (org.town.isNotEmpty || org.administrativeArea.isNotEmpty)
              _ContactRow(
                icon: Icons.place_outlined,
                text: [
                  org.town,
                  org.administrativeArea,
                ].where((part) => part.isNotEmpty).join(', '),
              ),
            if (org.website.isNotEmpty)
              _ContactRow(icon: Icons.language, text: org.website),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
