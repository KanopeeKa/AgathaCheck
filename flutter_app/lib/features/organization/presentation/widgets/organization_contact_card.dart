import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/organization.dart';

class OrganizationContactCard extends StatelessWidget {
  final Organization org;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const OrganizationContactCard({
    super.key,
    required this.org,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final hasContact = org.email.isNotEmpty ||
        org.phone.isNotEmpty ||
        org.address.isNotEmpty ||
        org.website.isNotEmpty;

    if (!hasContact) return const SizedBox.shrink();

    return Card(
      color: AppTheme.orgBlueDarker,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (org.email.isNotEmpty)
              _ContactRow(icon: Icons.email, text: org.email, colorScheme: colorScheme),
            if (org.phone.isNotEmpty)
              _ContactRow(icon: Icons.phone, text: org.phone, colorScheme: colorScheme),
            if (org.address.isNotEmpty)
              _ContactRow(icon: Icons.location_on, text: org.address, colorScheme: colorScheme),
            if (org.website.isNotEmpty)
              _ContactRow(icon: Icons.language, text: org.website, colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;

  const _ContactRow({required this.icon, required this.text, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
