import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/organization.dart';

class OrgPresentationLegalBlock extends StatelessWidget {
  const OrgPresentationLegalBlock({
    super.key,
    required this.org,
    required this.l,
  });

  final Organization org;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final entries = <({String label, String value})>[];
    if (org.legalIdentifier1.isNotEmpty) {
      entries.add((
        label: l.orgLegalIdentifierRna,
        value: org.legalIdentifier1,
      ));
    }
    if (org.legalIdentifier2.isNotEmpty) {
      entries.add((
        label: l.orgLegalIdentifierSiren,
        value: org.legalIdentifier2,
      ));
    }
    if (org.legalIdentifier3.isNotEmpty) {
      entries.add((
        label: l.orgLegalIdentifierSiret,
        value: org.legalIdentifier3,
      ));
    }

    if (entries.isEmpty) return const SizedBox.shrink();

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
              l.orgPresentationLegalTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        entry.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
