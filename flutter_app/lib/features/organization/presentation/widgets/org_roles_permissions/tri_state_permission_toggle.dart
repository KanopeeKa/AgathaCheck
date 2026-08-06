import 'package:flutter/material.dart';

import 'staged_permissions_controller.dart';

/// Tri-state toggle for bulk permission editing when selected people disagree.
class TriStatePermissionToggle extends StatelessWidget {
  const TriStatePermissionToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.showPending = false,
    this.semanticsLabel,
  });

  final TriState value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final bool showPending;
  final String? semanticsLabel;

  bool? get _checkboxValue {
    switch (value) {
      case TriState.on:
        return true;
      case TriState.off:
        return false;
      case TriState.indeterminate:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget trailing;
    if (showPending) {
      trailing = Semantics(
        label: 'Pending change',
        child: Container(
          key: const Key('org_permission_pending_indicator'),
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      );
    } else {
      trailing = const SizedBox(width: 18);
    }

    return Semantics(
      label: semanticsLabel,
      toggled: value == TriState.on
          ? true
          : (value == TriState.indeterminate ? null : false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            key: Key('org_permission_tri_state_${value.name}'),
            tristate: true,
            value: _checkboxValue,
            onChanged: enabled && onChanged != null
                ? (next) {
                    if (value == TriState.indeterminate) {
                      onChanged!(true);
                      return;
                    }
                    onChanged!(next ?? true);
                  }
                : null,
          ),
          trailing,
        ],
      ),
    );
  }
}
