import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class SharedPetOwnerCard extends StatelessWidget {
  final Map<String, dynamic> ownerData;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const SharedPetOwnerCard({
    super.key,
    required this.ownerData,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final first = ownerData['first_name'] as String? ?? '';
    final displayName = first.trim().isNotEmpty
        ? first.trim()
        : l.sharedPetLinkIdentityUnavailable;

    return Card(
      child: ListTile(
        leading: Icon(Icons.person, color: colorScheme.primary),
        title: Text(displayName, style: theme.textTheme.titleMedium),
      ),
    );
  }
}
