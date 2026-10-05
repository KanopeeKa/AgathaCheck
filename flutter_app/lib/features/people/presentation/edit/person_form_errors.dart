import '../../../../l10n/app_localizations.dart';
import '../../application/people_api_exception.dart';

String personFormSaveErrorMessage(AppLocalizations l, PeopleApiException e) {
  switch (e.code) {
    case 'validation_failed':
      return l.peopleSaveValidationError;
    case 'linked_identity_read_only':
      return l.peopleEditLinkedReadOnlyError;
    case 'forbidden':
      return l.peopleSaveError;
    default:
      return l.peopleSaveError;
  }
}

String personFormDeleteErrorMessage(AppLocalizations l, PeopleApiException e) {
  if (e.code == 'contact_in_use') {
    return l.peopleUsagesBlockedDelete;
  }
  return l.peopleRemoveError;
}
