import 'package:flutter/material.dart';

class SharedPetAcceptSection extends StatelessWidget {
  final bool isLoggedIn;
  final bool accepting;
  final VoidCallback onAccept;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final String promptText;
  final String buttonText;

  const SharedPetAcceptSection({
    super.key,
    required this.isLoggedIn,
    required this.accepting,
    required this.onAccept,
    required this.theme,
    required this.colorScheme,
    required this.promptText,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) return const SizedBox.shrink();
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
