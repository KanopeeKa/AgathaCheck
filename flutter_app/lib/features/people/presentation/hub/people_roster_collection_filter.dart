import 'package:pet_profile_app/core/widgets/collection_filter/collection_filter.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../domain/entities/roster.dart';
import 'roster_hub_query.dart';

abstract final class PeopleRosterCollectionFilterIds {
  static const primary = [
    PeopleRosterFilterIds.group,
    PeopleRosterFilterIds.kind,
    PeopleRosterFilterIds.pet,
    PeopleRosterFilterIds.status,
  ];
}

List<CollectionFilterDimension> peopleRosterFilterDimensions(
  AppLocalizations l,
  Roster roster,
) {
  final petChoices = <CollectionFilterChoice>{};
  for (final contact in roster.contacts) {
    for (final pet in contact.pets) {
      petChoices.add(CollectionFilterChoice(id: pet.petId, label: pet.petName));
    }
  }

  return [
    CollectionFilterDimension(
      id: PeopleRosterFilterIds.group,
      label: l.peopleFilterGroupLabel,
      choices: [
        CollectionFilterChoice(
          id: PeopleRosterFilterIds.groupHousehold,
          label: l.peopleFilterHousehold,
        ),
        CollectionFilterChoice(
          id: PeopleRosterFilterIds.groupCarers,
          label: l.peopleFilterCarers,
        ),
        CollectionFilterChoice(
          id: PeopleRosterFilterIds.groupProfessionals,
          label: l.peopleFilterProfessionals,
        ),
      ],
    ),
    CollectionFilterDimension(
      id: PeopleRosterFilterIds.kind,
      label: l.peopleKindLabel,
      choices: [
        CollectionFilterChoice(
          id: PeopleRosterFilterIds.kindPerson,
          label: l.peopleKindPerson,
        ),
        CollectionFilterChoice(
          id: PeopleRosterFilterIds.kindOrganisation,
          label: l.peopleKindOrganisation,
        ),
      ],
    ),
    CollectionFilterDimension(
      id: PeopleRosterFilterIds.pet,
      label: l.peopleFilterPetLabel,
      choices: petChoices.toList(),
    ),
    CollectionFilterDimension(
      id: PeopleRosterFilterIds.status,
      label: l.eventFilterStatusLabel,
      choices: [
        CollectionFilterChoice(
          id: PeopleRosterFilterIds.statusActive,
          label: l.peopleStatusActive,
        ),
        CollectionFilterChoice(
          id: PeopleRosterFilterIds.statusInactive,
          label: l.peopleStatusInactive,
        ),
      ],
    ),
  ];
}
