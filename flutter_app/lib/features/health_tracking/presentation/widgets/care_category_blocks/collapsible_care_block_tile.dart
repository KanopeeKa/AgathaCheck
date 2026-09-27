import 'package:flutter/material.dart';

/// Collapsed optional block — expands when [hasContent] or user opens it.
class CollapsibleCareBlockTile extends StatefulWidget {
  const CollapsibleCareBlockTile({
    super.key,
    required this.title,
    required this.collapsedLabel,
    required this.hasContent,
    required this.child,
  });

  final String title;
  final String collapsedLabel;
  final bool hasContent;
  final Widget child;

  @override
  State<CollapsibleCareBlockTile> createState() =>
      _CollapsibleCareBlockTileState();
}

class _CollapsibleCareBlockTileState extends State<CollapsibleCareBlockTile> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.hasContent;
  }

  @override
  void didUpdateWidget(CollapsibleCareBlockTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasContent && !_expanded) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_expanded && !widget.hasContent) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          key: Key('care_block_add_${widget.title}'),
          onPressed: () => setState(() => _expanded = true),
          child: Text(widget.collapsedLabel),
        ),
      );
    }

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(8),
      child: ExpansionTile(
        key: Key('care_block_expansion_${widget.title}'),
        initiallyExpanded: widget.hasContent,
        onExpansionChanged: (open) => setState(() => _expanded = open),
        title: Text(
          widget.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
