import 'package:flutter/material.dart';

/// Numeric badge for Guardian Care (Actions) primary nav — FR-CR-2.
class PetCareNavAttentionBadge extends StatelessWidget {
  const PetCareNavAttentionBadge({
    super.key,
    required this.count,
    required this.child,
  });

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    final label = count > 99 ? '99+' : '$count';
    return Badge(
      key: const Key('pet_care_nav_attention_badge'),
      label: Text(label),
      child: child,
    );
  }
}
