import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

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
        color: Colors.green.shade50,
        child: InkWell(
          onTap: onPressed,
          splashColor: Colors.green.shade100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 22,
                  color: Colors.green.shade700,
                ),
                const SizedBox(height: 4),
                Text(
                  l.markAsDone,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.green.shade700,
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
        color: Colors.orange.shade50,
        child: InkWell(
          onTap: onPressed,
          splashColor: Colors.orange.shade100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.undo, size: 22, color: Colors.orange.shade700),
                const SizedBox(height: 4),
                Text(
                  l.undoComplete,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange.shade700,
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
        color: Colors.orange.shade50,
        child: InkWell(
          onTap: () => _showSnoozePicker(context),
          splashColor: Colors.orange.shade100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.snooze, size: 18, color: Colors.orange.shade700),
                const SizedBox(height: 2),
                Text(
                  l.snooze,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange.shade700,
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

  void _showSnoozePicker(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    int selectedDays = 1;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.snooze, color: Colors.orange.shade700, size: 22),
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
                                      ? Colors.orange.shade800
                                      : Colors.grey,
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
                    backgroundColor: Colors.orange.shade700,
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
}
