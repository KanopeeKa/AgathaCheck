import 'package:flutter/material.dart';

/// One labelled action for [ScreenOverflowActions].
class ScreenOverflowAction {
  const ScreenOverflowAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.key,
    this.menuItemKey,
    this.semanticsIdentifier,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Key? key;
  final Key? menuItemKey;
  final String? semanticsIdentifier;
}

/// App-bar overflow menu for secondary screen actions (Card E).
///
/// - 0 actions → nothing rendered
/// - 1 action → single [IconButton] with tooltip
/// - 2+ actions → [PopupMenuButton] with icon + text rows
class ScreenOverflowActions extends StatelessWidget {
  const ScreenOverflowActions({
    super.key,
    required this.actions,
    this.menuKey,
    this.menuSemanticsIdentifier,
    this.tooltip,
  });

  final List<ScreenOverflowAction> actions;
  final Key? menuKey;
  final String? menuSemanticsIdentifier;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    if (actions.length == 1) {
      final action = actions.first;
      return Semantics(
        identifier: action.semanticsIdentifier,
        button: true,
        child: IconButton(
          key: action.key,
          tooltip: action.label,
          icon: Icon(action.icon),
          onPressed: action.onPressed,
        ),
      );
    }

    return Semantics(
      identifier: menuSemanticsIdentifier ?? 'screen_overflow_actions_menu',
      button: true,
      child: PopupMenuButton<int>(
        key: menuKey ?? const Key('screen_overflow_actions_menu'),
        tooltip: tooltip,
        icon: const Icon(Icons.more_vert),
        onSelected: (index) => actions[index].onPressed(),
        itemBuilder: (context) => [
          for (var i = 0; i < actions.length; i++)
            PopupMenuItem<int>(
              key: actions[i].menuItemKey,
              value: i,
              child: Semantics(
                identifier: actions[i].semanticsIdentifier,
                child: ListTile(
                  leading: Icon(actions[i].icon),
                  title: Text(actions[i].label),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
