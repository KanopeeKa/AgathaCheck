import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/health_providers.dart';

/// App-bar navigation button for the To Do (events) screen.
///
/// When any health entry is due or overdue, the icon is shown in red, bold,
/// and 20% larger than the default app-bar icon size.
class EventsNavIconButton extends ConsumerWidget {
  const EventsNavIconButton({super.key});

  static const double baseIconSize = 24;
  static const double alertScale = 1.2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final hasDueOrOverdue = ref.watch(hasDueOrOverdueEventsProvider);
    final theme = Theme.of(context);

    return IconButton(
      icon: Icon(
        Icons.list_alt,
        size: hasDueOrOverdue ? baseIconSize * alertScale : baseIconSize,
        color: hasDueOrOverdue ? theme.colorScheme.error : null,
        weight: hasDueOrOverdue ? 700 : null,
        fill: hasDueOrOverdue ? 1.0 : null,
      ),
      tooltip: l.events,
      onPressed: () => context.go('/health'),
    );
  }
}
