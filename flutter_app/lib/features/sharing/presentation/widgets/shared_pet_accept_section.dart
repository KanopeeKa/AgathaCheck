import 'package:flutter/material.dart';

import '../../../../core/widgets/invite_recipient_block.dart';

class SharedPetAcceptSection extends StatelessWidget {
  final bool isLoggedIn;
  final bool accepting;
  final VoidCallback onAccept;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final String promptText;
  final String buttonText;

  /// When set, signed-out viewers see [InviteRecipientBlock] instead of nothing.
  final String? invitePath;
  final String? inviterName;
  final String? petsSummary;
  final String? scopeDescription;

  const SharedPetAcceptSection({
    super.key,
    required this.isLoggedIn,
    required this.accepting,
    required this.onAccept,
    required this.theme,
    required this.colorScheme,
    required this.promptText,
    required this.buttonText,
    this.invitePath,
    this.inviterName,
    this.petsSummary,
    this.scopeDescription,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      final path = invitePath;
      final scope = scopeDescription;
      if (path == null || scope == null) return const SizedBox.shrink();
      return InviteRecipientBlock(
        invitePath: path,
        scopeDescription: scope,
        inviterName: inviterName,
        petsSummary: petsSummary,
      );
    }
    return Card(
      color: colorScheme.primaryContainer.withAlpha(80),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.person_add, size: 32, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              promptText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: accepting ? null : onAccept,
              icon: accepting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
