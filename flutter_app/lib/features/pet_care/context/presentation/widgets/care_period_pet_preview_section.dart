import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/care_period_coverage.dart';
import '../care_period_coverage_copy.dart';

/// Per-pet reassurance during absence create — no care enumeration (D-004).
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
                  final message = _errorMessage;
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
                l.careContextAwayCreateReassuranceIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (CarePeriodCoverageCopy.indeterminateQualifier(l, result!) !=
                  null) ...[
                const SizedBox(height: 8),
                Text(
                  CarePeriodCoverageCopy.indeterminateQualifier(l, result!)!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
