import 'add_person_entry.dart';

/// Route extra for `/pc/people/new`.
class AddPersonRouteArgs {
  const AddPersonRouteArgs({this.popResultOnSave = false, this.initialEntry});

  final bool popResultOnSave;
  final AddPersonEntry? initialEntry;
}
