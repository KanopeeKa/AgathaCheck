import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Facts-only evidence list for CIM safeguards (no diagnosis).
class CimEvidenceView extends StatelessWidget {
  const CimEvidenceView({super.key, required this.evidence});

  final Map<String, dynamic> evidence;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final measurementCount = evidence['measurement_count'];
    final direction = evidence['direction'] as String?;

    final facts = <String>[];
    if (measurementCount is num) {
      facts.add(l.careSafeguardEvidenceMeasurementCount(measurementCount.toInt()));
    }
    if (direction == 'down') {
      facts.add(l.careSafeguardEvidenceTrendDown);
    }

    if (facts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.careSafeguardEvidenceTitle,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        ...facts.map(
          (fact) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              fact,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
