import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_adoption_placements_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_custody_transfers_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_foster_placements_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_shares_section.dart';

/// Cross-experience surface for administrative actions (accept/decline, etc.).
///
/// Opened from notification bell deep links when a pending object needs action.
class PendingActionsScreen extends ConsumerWidget {
  const PendingActionsScreen({super.key, this.focus});

  /// Optional section focus from query param (`foster`, `adoption`, `custody`, `share`).
  final String? focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.notificationActionNeeded),
      ),
      body: ListView(
        key: const Key('pending_actions_screen'),
        padding: const EdgeInsets.all(16),
        children: [
          if (_showsSection('share', focus))
            const PendingSharesSection(),
          if (_showsSection('foster', focus))
            const PendingFosterPlacementsSection(),
          if (_showsSection('adoption', focus))
            const PendingAdoptionPlacementsSection(),
          if (_showsSection('custody', focus))
            const PendingCustodyTransfersSection(),
        ],
      ),
    );
  }

  bool _showsSection(String section, String? focus) {
    if (focus == null || focus.isEmpty) return true;
    return focus == section;
  }
}
