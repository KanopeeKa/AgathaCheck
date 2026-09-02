import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../domain/entities/pet.dart';
import 'pet_card.dart';

class PersonalPetsSection extends StatelessWidget {
  final List<Pet> personalActive;
  final String? orgFilter;
  final dynamic l;
  final ThemeData theme;
  final WidgetRef ref;
  final BuildContext parentContext;

  const PersonalPetsSection({
    super.key,
    required this.personalActive,
    required this.orgFilter,
    required this.l,
    required this.theme,
    required this.ref,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    if (personalActive.isEmpty && orgFilter == '_personal') {
      return _EmptySection(message: l.noPetsYet);
    }
    if (personalActive.isEmpty) return const SizedBox.shrink();

    final sorted = [...personalActive];
    sortPetsByCreatedAt(sorted);

    return PetTileStrip(
      useWrap: true,
      pets: sorted,
      onPetTap: (pet) => openPetDetail(context, pet.id),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
