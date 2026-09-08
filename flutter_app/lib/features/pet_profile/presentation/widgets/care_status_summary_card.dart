import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/care_status.dart';

/// Pet profile Care Status banner (three-state semantics).
class CareStatusSummaryCard extends StatelessWidget {
  const CareStatusSummaryCard({
    super.key,
    required this.status,
    this.onReview,
    this.onViewAction,
  });

  final CareStatus status;
  final VoidCallback? onReview;
  final VoidCallback? onViewAction;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final (title, body, accent, surface) = switch (status) {
      CareStatus.allSet => (
        l.careStatusAllSet,
        l.careStatusAllSetBody,
        AppColorTokens.success,
        AppColorTokens.surface,
      ),
      CareStatus.worthACheck => (
        l.careStatusWorthACheck,
        null,
        AppColorTokens.info,
        AppColorTokens.info.withValues(alpha: 0.08),
      ),
      CareStatus.timeToFollowUp => (
        l.careStatusTimeToFollowUp,
        null,
        AppColorTokens.petCarePrimary,
        AppColorTokens.petCareLight,
      ),
    };

    final actionLabel = status == CareStatus.worthACheck
        ? l.careStatusReviewAction
        : l.careStatusViewAction;
    final onAction = status == CareStatus.worthACheck ? onReview : onViewAction;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(switch (status) {
                CareStatus.allSet => Icons.check_circle_outline,
                CareStatus.worthACheck => Icons.info_outline,
                CareStatus.timeToFollowUp => Icons.schedule_outlined,
              }, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (body != null) ...[
                      const SizedBox(height: 4),
                      Text(body, style: theme.textTheme.bodyMedium),
                    ],
                    if (status != CareStatus.allSet && onAction != null) ...[
                      const SizedBox(height: 8),
                      TextButton(onPressed: onAction, child: Text(actionLabel)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
