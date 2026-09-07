import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Frozen MVP: foster placement pending actions are not shown.
class PendingFosterPlacementsSection extends ConsumerWidget {
  const PendingFosterPlacementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
