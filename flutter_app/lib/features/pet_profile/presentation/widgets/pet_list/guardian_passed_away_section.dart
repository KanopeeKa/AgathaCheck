import 'package:flutter/material.dart';

import '../../../domain/entities/pet.dart';
import '../pet_card.dart';
import 'pet_list_section_header.dart';

/// Passed-away section for the embedded Guardian All Pets shell.
///
/// Renders each passed-away pet using a [cardBuilder] (i.e. [GuardianFullListPetCard])
/// so they receive the Operations Desk treatment — ownership accent strip,
/// lifecycle badge, care urgency signal — instead of the default [PetCard].
///
/// Only used when [PetListScreen] is embedded in the guardian shell; the
/// standalone [PassedAwayPetsSection] (ExpansionTile / PetCard) is unchanged.
class GuardianPassedAwaySection extends StatelessWidget {
  const GuardianPassedAwaySection({
    super.key,
    required this.pets,
    required this.header,
    required this.cardBuilder,
  });

  final List<Pet> pets;
  final String header;
  final Widget Function(Pet) cardBuilder;

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) return const SizedBox.shrink();
    final sorted = [...pets];
    sortPetsByCreatedAt(sorted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PetListSectionHeader(
          icon: Icons.favorite_border,
          title: header,
          count: sorted.length,
        ),
        for (final pet in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: cardBuilder(pet),
          ),
      ],
    );
  }
}
