import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';

class HealthEntryOpenButton extends StatelessWidget {
  const HealthEntryOpenButton({super.key, this.onPressed, this.semanticKey});

  final VoidCallback? onPressed;
  final Key? semanticKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      key: semanticKey,
      width: 48,
      child: Material(
        color: AppColorTokens.surfaceAlt,
        child: InkWell(
          onTap: onPressed,
          splashColor: AppColorTokens.border,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.open_in_new, size: 18, color: AppColorTokens.muted),
                const SizedBox(height: 2),
                Text(
                  l.open,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColorTokens.muted,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HealthEntryMarkDoneButton extends StatelessWidget {
  const HealthEntryMarkDoneButton({
    super.key,
    this.onPressed,
    required this.petStripWidth,
  });

  final VoidCallback? onPressed;
  final double petStripWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: petStripWidth * 2,
      child: Material(
        color: AppColorTokens.successLight,
        child: InkWell(
          onTap: onPressed,
          splashColor: AppColorTokens.successLight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 22,
                  color: AppColorTokens.success,
                ),
                const SizedBox(height: 4),
                Text(
                  l.markAsDone,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColorTokens.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HealthEntryUndoCompleteButton extends StatelessWidget {
  const HealthEntryUndoCompleteButton({
    super.key,
    this.onPressed,
    required this.petStripWidth,
  });

  final VoidCallback? onPressed;
  final double petStripWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: petStripWidth * 2,
      child: Material(
        color: AppColorTokens.warmAccentLight,
        child: InkWell(
          onTap: onPressed,
          splashColor: AppColorTokens.warmAccentLight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.undo, size: 22, color: AppColorTokens.warmAccent),
                const SizedBox(height: 4),
                Text(
                  l.undoComplete,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColorTokens.heading,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HealthEntrySnoozeButton extends StatelessWidget {
  const HealthEntrySnoozeButton({super.key, this.onSnooze});

  final void Function(int days)? onSnooze;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: 48,
      child: Material(
        color: AppColorTokens.warmAccentLight,
        child: InkWell(
          onTap: () => showHealthEntrySnoozeDialog(context, onSnooze: onSnooze),
          splashColor: AppColorTokens.warmAccentLight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.snooze, size: 18, color: AppColorTokens.warning),
                const SizedBox(height: 2),
                Text(
                  l.snooze,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColorTokens.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Day-picker dialog for postponing a health entry occurrence.
Future<void> showHealthEntrySnoozeDialog(
  BuildContext context, {
  void Function(int days)? onSnooze,
}) async {
  final l = AppLocalizations.of(context)!;
  var selectedDays = 1;
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.snooze, color: AppColorTokens.warning, size: 22),
                const SizedBox(width: 8),
                Text('${l.snooze} Event'),
              ],
            ),
            content: SizedBox(
              height: 160,
              child: Column(
                children: [
                  Text(
                    'Postpone for how many days?',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setDialogState(() => selectedDays = index + 1);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 90,
                        builder: (context, index) {
                          final day = index + 1;
                          final isSelected = day == selectedDays;
                          return Center(
                            child: Text(
                              day == 1 ? '1 ${l.day}' : '$day ${l.days}',
                              style: TextStyle(
                                fontSize: isSelected ? 20 : 15,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColorTokens.warning
                                    : AppColorTokens.muted,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColorTokens.warning,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onSnooze?.call(selectedDays);
                },
                child: Text(
                  '${l.snooze} $selectedDays ${selectedDays == 1 ? l.day : l.days}',
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
