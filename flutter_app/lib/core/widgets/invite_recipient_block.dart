import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../router/invite_return.dart';

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
