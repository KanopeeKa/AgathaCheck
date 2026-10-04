import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/contact_summary.dart';
import '../labels/people_labels.dart';

String personPetsLine(AppLocalizations l, List<ContactPetLink> pets) {
  if (pets.isEmpty) return '';
  return pets
      .map((pet) {
        final rel = pet.relationshipKind.label(l);
        if (pet.isPrimary) {
          return '${pet.petName} ($rel)';
        }
        return pet.petName;
      })
      .join(', ');
}

String? personContextLine(ContactSummary contact, AppLocalizations l) {
  final absence = contact.nextAbsence;
  if (absence == null) return null;
  return l.peopleCardLookingAfter(absence.startsOn, absence.endsOn);
}
