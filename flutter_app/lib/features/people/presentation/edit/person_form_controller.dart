import 'package:flutter/foundation.dart';

import '../../application/people_api_exception.dart';
import '../../domain/entities/contact_detail.dart';
import '../../domain/entities/contact_summary.dart';
import '../../domain/enums/contact_group.dart';
import '../../domain/enums/contact_kind.dart';
import '../../domain/enums/contact_role.dart';
import '../../domain/enums/contact_status.dart';

/// Shared form state for person add (c6) and edit (c5).
class PersonFormController extends ChangeNotifier {
  PersonFormController({required ContactDetail initial})
    : _baseline = initial,
      _kind = initial.kind,
      _roles = Set<ContactRole>.from(initial.roles),
      _name = initial.name,
      _phone = initial.phone ?? '',
      _email = initial.email ?? '',
      _address = initial.address ?? '',
      _website = initial.website ?? '',
      _privateNote = initial.privateNote,
      _householdNote = initial.householdNote ?? '',
      _worksAtContactId = initial.worksAtContactId;

  final ContactDetail _baseline;

  /// Empty draft for the unified add-person flow.
  static PersonFormController forNewContact({required ContactKind kind}) {
    return PersonFormController(
      initial: ContactDetail(
        id: '',
        directoryId: '',
        directory: const ContactDirectoryRef(type: 'personal'),
        kind: kind,
        name: '',
        roles: const [],
        group: ContactGroup.carer,
        status: ContactStatus.active,
      ),
    );
  }

  ContactKind _kind;
  Set<ContactRole> _roles;
  String _name;
  String _phone;
  String _email;
  String _address;
  String _website;
  String _privateNote;
  String _householdNote;
  String? _worksAtContactId;

  String? nameError;
  String? emailError;

  ContactDetail get baseline => _baseline;
  ContactKind get kind => _kind;
  Set<ContactRole> get roles => Set.unmodifiable(_roles);
  String get name => _name;
  String get phone => _phone;
  String get email => _email;
  String get address => _address;
  String get website => _website;
  String get privateNote => _privateNote;
  String get householdNote => _householdNote;
  String? get worksAtContactId => _worksAtContactId;

  bool get isLinked => _baseline.linkedAccount != null;
  bool get isInactive => _baseline.inactiveAt != null;
  bool get showHouseholdNote => _baseline.directory.isHousehold;

  bool get isDirty {
    if (_kind != _baseline.kind) return true;
    if (!_rolesEq(_roles, _baseline.roles)) return true;
    if (_name.trim() != _baseline.name) return true;
    if (_trimOrNull(_phone) != _baseline.phone) return true;
    if (_trimOrNull(_email) != _baseline.email) return true;
    if (_trimOrNull(_address) != _baseline.address) return true;
    if (_trimOrNull(_website) != _baseline.website) return true;
    if (_privateNote.trim() != _baseline.privateNote) return true;
    if (showHouseholdNote &&
        _trimOrNull(_householdNote) != _baseline.householdNote) {
      return true;
    }
    if (_worksAtContactId != _baseline.worksAtContactId) return true;
    return false;
  }

  void setKind(ContactKind value) {
    if (isLinked || _kind == value) return;
    _kind = value;
    notifyListeners();
  }

  void toggleRole(ContactRole role) {
    if (_roles.contains(role)) {
      _roles = Set.from(_roles)..remove(role);
    } else {
      _roles = Set.from(_roles)..add(role);
    }
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    nameError = null;
    notifyListeners();
  }

  void setPhone(String value) {
    _phone = value;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    emailError = null;
    notifyListeners();
  }

  void setAddress(String value) {
    _address = value;
    notifyListeners();
  }

  void setWebsite(String value) {
    _website = value;
    notifyListeners();
  }

  void setPrivateNote(String value) {
    _privateNote = value;
    notifyListeners();
  }

  void setHouseholdNote(String value) {
    _householdNote = value;
    notifyListeners();
  }

  void setWorksAtContactId(String? value) {
    _worksAtContactId = value;
    notifyListeners();
  }

  bool validate() {
    nameError = null;
    emailError = null;
    final trimmedName = _name.trim();
    if (trimmedName.isEmpty) {
      nameError = 'required';
      notifyListeners();
      return false;
    }
    final trimmedEmail = _email.trim();
    if (trimmedEmail.isNotEmpty && !trimmedEmail.contains('@')) {
      emailError = 'invalid';
      notifyListeners();
      return false;
    }
    return true;
  }

  Map<String, dynamic> buildPatch() {
    final patch = <String, dynamic>{};
    if (_kind != _baseline.kind) patch['kind'] = _kind.wireValue;
    if (_name.trim() != _baseline.name) patch['name'] = _name.trim();
    if (!_rolesEq(_roles, _baseline.roles)) {
      patch['roles'] = _roles.map((r) => r.wireValue).toList();
    }
    final phone = _trimOrNull(_phone);
    if (phone != _baseline.phone) patch['phone'] = phone;
    final email = _trimOrNull(_email);
    if (email != _baseline.email) patch['email'] = email;
    final address = _trimOrNull(_address);
    if (address != _baseline.address) patch['address'] = address;
    final website = _trimOrNull(_website);
    if (website != _baseline.website) patch['website'] = website;
    if (_privateNote.trim() != _baseline.privateNote) {
      patch['private_note'] = _privateNote.trim();
    }
    if (showHouseholdNote) {
      final note = _trimOrNull(_householdNote);
      if (note != _baseline.householdNote) {
        patch['household_note'] = note ?? '';
      }
    }
    if (_worksAtContactId != _baseline.worksAtContactId) {
      patch['works_at_contact_id'] = _worksAtContactId;
    }
    return patch;
  }

  Map<String, dynamic> buildReactivatePatch() => {'active': true};

  Map<String, dynamic> buildMarkInactivePatch() => {'active': false};

  PeopleApiException? mapSubmitException(Object error) {
    if (error is PeopleApiException) return error;
    return null;
  }
}

String? _trimOrNull(String value) {
  final t = value.trim();
  return t.isEmpty ? null : t;
}

bool _rolesEq(Set<ContactRole> a, List<ContactRole> b) {
  if (a.length != b.length) return false;
  for (final role in b) {
    if (!a.contains(role)) return false;
  }
  return true;
}
