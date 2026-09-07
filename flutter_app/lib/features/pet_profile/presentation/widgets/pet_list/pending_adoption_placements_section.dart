import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Frozen MVP: adoption placement pending actions are not shown.
class PendingAdoptionPlacementsSection extends ConsumerWidget {
  const PendingAdoptionPlacementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
