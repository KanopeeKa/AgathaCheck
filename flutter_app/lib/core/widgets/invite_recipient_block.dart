import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../router/invite_return.dart';

/// Error state for a failed primary load (mirrors shared `AsyncErrorState` until
/// integration merges phase 0 from main).
class AsyncErrorState extends StatelessWidget {
  const AsyncErrorState({
    super.key,
    this.title,
    this.detail,
    this.onRetry,
    this.retryKey,
  });

  final String? title;
  final String? detail;
  final VoidCallback? onRetry;
  final Key? retryKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hint = detail ?? (onRetry != null ? l.loadErrorRetryHint : null);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(Icons.error_outline, size: 32, color: scheme.error),
              ),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  title ?? l.loadErrorTitle,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 8),
                Text(
                  hint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: retryKey,
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l.retry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Signed-out preview block for invitation recipients (design review C-13.1 / X-3).
///
/// Shows who invited, what is offered, and one action to continue via `/landing`
/// with a validated `returnTo` for the current invite route.
class InviteRecipientBlock extends StatelessWidget {
  const InviteRecipientBlock({
    super.key,
    required this.invitePath,
    required this.scopeDescription,
    this.inviterName,
    this.petsSummary,
    this.householdSummary,
  });

  /// Current invite path (for example `/invite/abc`).
  final String invitePath;

  /// Localized access scope (role, tier, or carer duties).
  final String scopeDescription;

  final String? inviterName;
  final String? petsSummary;
  final String? householdSummary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayInviter = (inviterName != null && inviterName!.trim().isNotEmpty)
        ? inviterName!.trim()
        : l.sharedPetLinkIdentityUnavailable;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.inviteRecipientInvitedBy(displayInviter),
              style: theme.textTheme.titleLarge,
            ),
            if (petsSummary != null && petsSummary!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l.shareInviteLandingPets(petsSummary!),
                style: theme.textTheme.bodyLarge,
              ),
            ],
            if (householdSummary != null && householdSummary!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l.inviteRecipientHousehold(householdSummary!),
                style: theme.textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              l.inviteRecipientAccessScope(scopeDescription),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('invite_recipient_continue_account'),
              onPressed: () {
                final target = parseInviteReturnTo(invitePath) ?? invitePath;
                context.go(
                  appendInviteReturnQuery('/landing', target),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l.inviteContinueWithAccount),
            ),
          ],
        ),
      ),
    );
  }
}
