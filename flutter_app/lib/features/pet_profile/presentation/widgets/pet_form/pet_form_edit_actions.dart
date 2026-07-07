import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Delete and passed-away actions shown when editing a non-shared pet.
class PetFormEditActions extends StatelessWidget {
  const PetFormEditActions({
    super.key,
    required this.isLoading,
    required this.passedAway,
    required this.onDelete,
    required this.onPassedAway,
  });

  final bool isLoading;
  final bool passedAway;
  final VoidCallback onDelete;
  final VoidCallback onPassedAway;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('delete_pet_button'),
          onPressed: isLoading ? null : onDelete,
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          label: Text(
            l.deletePet,
            style: TextStyle(color: theme.colorScheme.error),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.colorScheme.error.withAlpha(120)),
          ),
        ),
        if (!passedAway) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('passed_away_button'),
            onPressed: isLoading ? null : onPassedAway,
            icon: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFF8800),
                  Color(0xFFFFFF00),
                  Color(0xFF00CC00),
                  Color(0xFF0066FF),
                  Color(0xFF8800CC),
                ],
              ).createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: const Icon(Icons.air, size: 20),
            ),
            label: Text(l.passedAway),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.outline.withAlpha(80)),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
