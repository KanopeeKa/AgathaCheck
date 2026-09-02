import 'package:flutter/material.dart';

import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/widgets/pet_card.dart';
import '../screens/guardian/guardian_dashboard_helpers.dart';
import 'guardian_dashboard_pet_card.dart';
import 'guardian_dashboard_section_header.dart';

/// Dashboard-aligned pet cards in a responsive wrap grid for guardian list screens.
class GuardianPetsTileGrid extends StatelessWidget {
  const GuardianPetsTileGrid({
    super.key,
    required this.pets,
    required this.careSummary,
    required this.onPetTap,
  });

  final List<Pet> pets;
  final GuardianTodayCareSummary? careSummary;
  final ValueChanged<Pet> onPetTap;

  static const double _spacing = 12;

  static int columnsForWidth(double width) {
    if (width >= 900) return 3;
    return 2;
  }

  static double cardWidthFor(double maxWidth) {
    final columns = columnsForWidth(maxWidth);
    final computed = (maxWidth - (columns - 1) * _spacing) / columns;
    final minWidth = guardianPetsListCardMinWidth(maxWidth);
    return computed < minWidth ? minWidth : computed;
  }

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) return const SizedBox.shrink();

    final sorted = [...pets];
    sortPetsByCreatedAt(sorted);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = cardWidthFor(constraints.maxWidth);
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final pet in sorted)
              SizedBox(
                width: cardWidth,
                child: GuardianDashboardPetCard(
                  pet: pet,
                  careState: careSummary == null
                      ? GuardianTodayPetCareState.clear
                      : guardianTodayPetCareState(pet, careSummary!),
                  onTap: () => onPetTap(pet),
                ),
              ),
          ],
        );
      },
    );
  }
}
