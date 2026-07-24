import 'package:flutter/material.dart';

/// Expandable landing path card — full-card button with experience accent fill.
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

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailColor = widget.onAccentColor.withValues(alpha: 0.9);
    final ctaLabel = _expanded ? widget.collapseLabel : widget.expandLabel;

    return Semantics(
      button: true,
      expanded: _expanded,
      label: '${widget.summary}. $ctaLabel',
      child: Material(
        color: widget.accentColor,
        elevation: 0,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggleExpanded,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, color: widget.onAccentColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.summary,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.onAccentColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: widget.onAccentColor,
                      size: 24,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.detail,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: detailColor,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  ctaLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: widget.onAccentColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: widget.onAccentColor,
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
