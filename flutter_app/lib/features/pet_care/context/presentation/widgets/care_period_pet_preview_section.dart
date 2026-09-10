import 'package:flutter/material.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/care_period_coverage.dart';
import '../care_period_coverage_copy.dart';

class CarePeriodPetPreviewSection extends StatelessWidget {
  const CarePeriodPetPreviewSection({
    super.key,
    required this.petName,
    required this.result,
  }) : _loading = false,
       _errorMessage = null,
       _onRetry = null;

  const CarePeriodPetPreviewSection.loading({super.key, required this.petName})
    : result = null,
      _loading = true,
      _errorMessage = null,
      _onRetry = null;

  const CarePeriodPetPreviewSection.error({
    super.key,
    required this.petName,
    required String message,
    required VoidCallback onRetry,
  }) : result = null,
       _loading = false,
       _errorMessage = message,
       _onRetry = onRetry;

  final String petName;
  final CarePeriodCoverageResult? result;
  final bool _loading;
  final String? _errorMessage;
  final VoidCallback? _onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      key: Key('care_period_preview_${petName.replaceAll(' ', '_')}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              petName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.careContextAwayPreviewLoading)),
                ],
              )
            else if (_errorMessage != null)
              Builder(
                builder: (context) {
                  final message = _errorMessage!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message),
                      if (_onRetry != null) ...[
                        const SizedBox(height: 8),
                        TextButton(onPressed: _onRetry, child: Text(l.retry)),
                      ],
                    ],
                  );
                },
              )
            else if (result != null) ...[
              Text(
                CarePeriodCoverageCopy.summary(l, result!),
                style: theme.textTheme.bodyLarge,
              ),
              if (CarePeriodCoverageCopy.indeterminateQualifier(l, result!) !=
                  null) ...[
                const SizedBox(height: 8),
                Text(
                  CarePeriodCoverageCopy.indeterminateQualifier(l, result!)!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (result!.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...result!.items.map((item) => _PreviewItemRow(item: item)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewItemRow extends StatelessWidget {
  const _PreviewItemRow({required this.item});

  final CarePeriodProjectionItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final parsed = parseCalendarDate(item.scheduledDate);
    final dateLabel = parsed == null
        ? item.scheduledDate
        : formatCalendarDateDisplay(parsed);
    final statusLabel = switch (item.status) {
      'completed' => l.careContextPreviewItemCompleted(dateLabel),
      'skipped' => l.careContextPreviewItemSkipped(dateLabel),
      _ => l.careContextPreviewItemPending(dateLabel),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.isPending ? Icons.circle_outlined : Icons.check_circle_outline,
            size: 18,
            color: item.isPending
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.bodyMedium),
                Text(
                  statusLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
