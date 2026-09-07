import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Frozen MVP: custody transfer pending actions are not shown.
class PendingCustodyTransfersSection extends ConsumerWidget {
  const PendingCustodyTransfersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
