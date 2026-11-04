import 'package:flutter/material.dart';

import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/core/widgets/pet_care_dashboard_section_header.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'all_care_closed_copy.dart';
import '../../screens/closed_care/closed_care_list_screen.dart';

/// Footer link on All care when the pet has closed care items (CARE-STATUS-R-021).
class AllCareClosedFooter extends StatelessWidget {
  const AllCareClosedFooter({
    super.key,
    required this.petId,
    required this.closedCount,
  });

  final String petId;
  final int closedCount;

  @override
  Widget build(BuildContext context) {
    if (closedCount <= 0) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Semantics(
        identifier: 'all_care_closed_care_link',
        container: true,
        child: PetCareDashboardSectionLink(
          linkKey: const Key('all_care_closed_care_link'),
          label: allCareClosedCareLinkLabel(l, closedCount),
          onPressed: () {
            final hostContext = context;
            Navigator.of(hostContext).push<void>(
              MaterialPageRoute<void>(
                builder: (listContext) => ClosedCareListScreen(
                  petId: petId,
                  onOpenEntry: (HealthEntry entry) {
                    openPetEventView(
                      hostContext,
                      petId: petId,
                      entryId: entry.id,
                    );
                    Navigator.of(listContext).pop();
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
