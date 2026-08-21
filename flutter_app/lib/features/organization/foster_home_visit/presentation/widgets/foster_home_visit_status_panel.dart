import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/foster_home_visit.dart';
import '../providers/foster_home_visit_providers.dart';

class FosterHomeVisitStatusPanel extends StatelessWidget {
  const FosterHomeVisitStatusPanel({
    super.key,
    required this.snapshot,
    this.showAddress = false,
  });

  final FosterHomeVisitStatusSnapshot snapshot;
  final bool showAddress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final active = snapshot.activeVisit;
    final validated = snapshot.latestValidated;

    if (active == null && validated == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l.fosterHomeVisitStatusEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (active != null) ...[
          _VisitStatusCard(
            title: l.fosterHomeVisitStatusActiveTitle,
            visit: active,
            showAddress: showAddress,
          ),
          const SizedBox(height: 12),
        ],
        if (validated != null)
          _VisitStatusCard(
            title: validated.outcome == FosterHomeVisitOutcome.yes &&
                    !showAddress
                ? l.fosterHomeVisitStatusApproved
                : l.fosterHomeVisitStatusLatestValidatedTitle,
            visit: validated,
            showAddress: showAddress,
          ),
      ],
    );
  }
}

class FosterHomeVisitHistoryList extends StatelessWidget {
  const FosterHomeVisitHistoryList({
    super.key,
    required this.visits,
  });

  final List<FosterHomeVisit> visits;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final history = visits
        .where((visit) => visit.status != FosterHomeVisitStatus.scheduled)
        .toList();

    if (history.isEmpty) {
      return Text(
        l.fosterHomeVisitHistoryEmpty,
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.fosterHomeVisitHistoryTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...history.map(
          (visit) => Card(
            key: Key('foster_home_visit_history_${visit.id}'),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                formatFosterHomeVisitDateTime(visit.visitDate, visit.visitTime),
              ),
              subtitle: Text(
                localizedFosterHomeVisitStatusLabel(l, visit.status),
              ),
              trailing: visit.outcome != null
                  ? Text(localizedFosterHomeVisitOutcomeLabel(l, visit.outcome!))
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _VisitStatusCard extends StatelessWidget {
  const _VisitStatusCard({
    required this.title,
    required this.visit,
    required this.showAddress,
  });

  final String title;
  final FosterHomeVisit visit;
  final bool showAddress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      key: Key('foster_home_visit_status_card_${visit.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatFosterHomeVisitDateTime(visit.visitDate, visit.visitTime),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              localizedFosterHomeVisitStatusLabel(l, visit.status),
            ),
            if (showAddress && visit.address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${l.fosterHomeVisitAddressLabel}: ${visit.address}'),
            ],
            if (visit.outcome != null) ...[
              const SizedBox(height: 8),
              Text(
                '${l.fosterHomeVisitOutcomeLabel}: ${localizedFosterHomeVisitOutcomeLabel(l, visit.outcome!)}',
              ),
              if (visit.outcomeReason.isNotEmpty)
                Text(visit.outcomeReason),
            ],
          ],
        ),
      ),
    );
  }
}
