import 'package:flutter/material.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Loading / error / empty states for the pet list body.
class PetListLoadingBody extends StatelessWidget {
  const PetListLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class PetListErrorBody extends StatelessWidget {
  const PetListErrorBody({
    super.key,
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

class PetListNoPetsEmptyBody extends StatelessWidget {
  const PetListNoPetsEmptyBody({
    super.key,
    required this.headline,
    required this.subtitle,
    required this.showSubtitle,
  });

  final String headline;
  final String subtitle;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.pets,
              size: 80,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(headline, style: theme.textTheme.headlineSmall),
          if (showSubtitle) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PetListFilterEmptyBody extends StatelessWidget {
  const PetListFilterEmptyBody({
    super.key,
    required this.message,
    required this.showClearFilter,
    required this.clearFilterLabel,
    required this.onClearFilter,
  });

  final String message;
  final bool showClearFilter;
  final String clearFilterLabel;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (showClearFilter) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onClearFilter,
              child: Text(clearFilterLabel),
            ),
          ],
        ],
      ),
    );
  }
}
