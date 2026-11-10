import 'package:flutter/foundation.dart';

import '../../domain/enums/contact_kind.dart';
import '../edit/person_form_controller.dart';
import 'add_person_app_access.dart';
import 'add_person_create_body.dart';
import 'add_person_entry.dart';
import 'add_person_pet_selection.dart';

class AddPersonFlowController extends ChangeNotifier {
  AddPersonFlowController({
    AddPersonEntry? initialEntry,
    List<String> initialPetIds = const [],
  }) : _initialPetIds = List.unmodifiable(initialPetIds),
       _entry = initialEntry,
       _form = PersonFormController.forNewContact(
         kind: initialEntry?.contactKind ?? ContactKind.person,
       );

  final List<String> _initialPetIds;
  AddPersonEntry? _entry;
  int _stepIndex = 0;
  final PersonFormController _form;
  final List<AddPersonPetSelection> _pets = [];
  AddPersonAppAccessChoice _appAccess = AddPersonAppAccessChoice.skip;
  String? _householdName;
  String? _rolesError;
  String? _petsLinkError;

  AddPersonEntry? get entry => _entry;
  int get stepIndex => _stepIndex;
  PersonFormController get form => _form;
  List<AddPersonPetSelection> get pets => List.unmodifiable(_pets);
  List<String> get initialPetIds => _initialPetIds;
  AddPersonAppAccessChoice get appAccess => _appAccess;
  String? get householdName => _householdName;
  String? get rolesError => _rolesError;
  String? get petsLinkError => _petsLinkError;

  static const int stepCount = 5;

  void selectEntry(AddPersonEntry value) {
    _entry = value;
    _form.setKind(value.contactKind);
    _rolesError = null;
    notifyListeners();
  }

  void setPets(List<AddPersonPetSelection> selections) {
    _pets
      ..clear()
      ..addAll(selections);
    notifyListeners();
  }

  void touchPets() {
    _petsLinkError = null;
    notifyListeners();
  }

  bool get _selectedPetMissingLinkKind =>
      _pets.any((p) => p.selected && !p.linkKindChosen);

  void setAppAccess(AddPersonAppAccessChoice value) {
    _appAccess = value;
    notifyListeners();
  }

  void setHouseholdName(String value) {
    _householdName = value.trim().isEmpty ? null : value.trim();
    notifyListeners();
  }

  bool canAdvanceFromCurrentStep() {
    final entry = _entry;
    if (entry == null) return false;
    switch (_stepIndex) {
      case 0:
        return _entry != null;
      case 1:
        return _form.name.trim().isNotEmpty;
      case 2:
        return rolesValidForAdd(
          _form.roles,
          requiresRoles: entry.requiresRoles,
        );
      case 3:
        return !_selectedPetMissingLinkKind;
      case 4:
        return true;
      default:
        return false;
    }
  }

  bool advanceStep() {
    if (_stepIndex == 1 && !_form.validate()) {
      notifyListeners();
      return false;
    }
    if (!canAdvanceFromCurrentStep()) {
      if (_stepIndex == 2 && _entry != null) {
        _rolesError = 'required';
        notifyListeners();
      }
      if (_stepIndex == 3 && _selectedPetMissingLinkKind) {
        _petsLinkError = 'required';
        notifyListeners();
      }
      return false;
    }
    if (_stepIndex >= stepCount - 1) return false;
    _stepIndex++;
    if (_stepIndex == 4 && _entry != null && !_entry!.showsAppAccessStep) {
      // Professionals / organisations skip app-access UI but stay on review step.
    }
    _rolesError = null;
    _petsLinkError = null;
    notifyListeners();
    return true;
  }

  bool validatePetLinksForSave() {
    if (!_selectedPetMissingLinkKind) return true;
    _petsLinkError = 'required';
    notifyListeners();
    return false;
  }

  void backStep() {
    if (_stepIndex <= 0) return;
    _stepIndex--;
    notifyListeners();
  }

  Map<String, dynamic> buildCreateBody({String? householdId}) {
    return buildAddPersonCreateBody(
      form: _form,
      pets: _pets,
      householdId: householdId,
    );
  }
}
