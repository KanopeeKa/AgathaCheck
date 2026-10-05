import '../../domain/entities/contact_summary.dart';

sealed class PeoplePickerResult {
  const PeoplePickerResult();
}

final class PeoplePickerContactResult extends PeoplePickerResult {
  const PeoplePickerContactResult(this.contact);

  final ContactSummary contact;
}

final class PeoplePickerNoneResult extends PeoplePickerResult {
  const PeoplePickerNoneResult();
}

final class PeoplePickerTypedNameResult extends PeoplePickerResult {
  const PeoplePickerTypedNameResult(this.name);

  final String name;
}
