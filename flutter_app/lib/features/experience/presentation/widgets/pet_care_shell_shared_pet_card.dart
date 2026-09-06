import 'package:flutter/material.dart';

import '../../../pet_profile/domain/entities/pet.dart';

/// Shared-pet wrapper for the guardian shell — swipe-to-hide removed per UX review.
class PetCareShellSharedPetCard extends StatelessWidget {
  const PetCareShellSharedPetCard({
    super.key,
    required this.pet,
    required this.child,
  });

  final Pet pet;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
