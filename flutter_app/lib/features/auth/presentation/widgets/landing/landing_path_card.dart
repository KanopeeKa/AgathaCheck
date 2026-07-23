import 'package:flutter/material.dart';

/// Expandable landing path card with experience accent (guardian plum or org teal).
class LandingPathCard extends StatefulWidget {
  const LandingPathCard({
    super.key,
    required this.summary,
    required this.expandLabel,
    required this.collapseLabel,
    required this.detail,
    required this.accentColor,
    required this.onAccentColor,
    required this.icon,
  });

  final String summary;
  final String expandLabel;
  final String collapseLabel;
  final String detail;
  final Color accentColor;
  final Color onAccentColor;
  final IconData icon;

  @override
  State<LandingPathCard> createState() => _LandingPathCardState();
}

class _LandingPathCardState extends State<LandingPathCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.icon, color: widget.accentColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.summary,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              Text(
                widget.detail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  foregroundColor: widget.onAccentColor,
                  backgroundColor: widget.accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _expanded ? widget.collapseLabel : widget.expandLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
