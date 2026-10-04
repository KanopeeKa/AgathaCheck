import '../enums/contact_group.dart';
import '../enums/contact_kind.dart';
import '../enums/contact_role.dart';
import '../enums/contact_status.dart';
import 'contact_summary.dart';

class ContactStaffMember {
  const ContactStaffMember({
    required this.id,
    required this.name,
    required this.kind,
    required this.roles,
  });

  final String id;
  final String name;
  final ContactKind kind;
  final List<ContactRole> roles;

  @override
  bool operator ==(Object other) {
    return other is ContactStaffMember &&
        other.id == id &&
        other.name == name &&
        other.kind == kind &&
        _rolesEq(other.roles, roles);
  }

  @override
  int get hashCode => Object.hash(id, name, kind, Object.hashAll(roles));
}

class LinkedAccount {
  const LinkedAccount({
    required this.userId,
    required this.displayName,
    this.photoUrl,
  });

  final String userId;
  final String displayName;
  final String? photoUrl;

  @override
  bool operator ==(Object other) {
    return other is LinkedAccount &&
        other.userId == userId &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode => Object.hash(userId, displayName, photoUrl);
}

class ContactWorksAtDetail {
  const ContactWorksAtDetail({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;

  @override
  bool operator ==(Object other) {
    return other is ContactWorksAtDetail &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.email == email &&
        other.address == address;
  }

  @override
  int get hashCode => Object.hash(id, name, phone, email, address);
}

class ContactDetail {
  const ContactDetail({
    required this.id,
    required this.directoryId,
    required this.directory,
    required this.kind,
    required this.name,
    required this.roles,
    required this.group,
    required this.status,
    this.phone,
    this.email,
    this.address,
    this.website,
    this.worksAtContactId,
    this.linkedUserId,
    this.inactiveAt,
    this.legacyVetId,
    this.privateNote = '',
    this.householdNote,
    this.worksAt,
    this.staff = const [],
    this.usageCounts = const {},
    this.linkedAccount,
  });

  final String id;
  final String directoryId;
  final ContactDirectoryRef directory;
  final ContactKind kind;
  final String name;
  final List<ContactRole> roles;
  final ContactGroup group;
  final ContactStatus status;
  final String? phone;
  final String? email;
  final String? address;
  final String? website;
  final String? worksAtContactId;
  final String? linkedUserId;
  final DateTime? inactiveAt;
  final String? legacyVetId;
  final String privateNote;
  final String? householdNote;
  final ContactWorksAtDetail? worksAt;
  final List<ContactStaffMember> staff;
  final Map<String, int> usageCounts;
  final LinkedAccount? linkedAccount;

  ContactSummary toSummary() => ContactSummary(
    id: id,
    directory: directory,
    kind: kind,
    name: name,
    roles: roles,
    group: group,
    status: status,
    linkedUserId: linkedUserId,
    legacyVetId: legacyVetId,
  );

  @override
  bool operator ==(Object other) {
    return other is ContactDetail &&
        other.id == id &&
        other.directoryId == directoryId &&
        other.directory == directory &&
        other.kind == kind &&
        other.name == name &&
        _rolesEq(other.roles, roles) &&
        other.group == group &&
        other.status == status &&
        other.phone == phone &&
        other.email == email &&
        other.address == address &&
        other.website == website &&
        other.worksAtContactId == worksAtContactId &&
        other.linkedUserId == linkedUserId &&
        other.inactiveAt == inactiveAt &&
        other.legacyVetId == legacyVetId &&
        other.privateNote == privateNote &&
        other.householdNote == householdNote &&
        other.worksAt == worksAt &&
        _staffEq(other.staff, staff) &&
        _mapEq(other.usageCounts, usageCounts) &&
        other.linkedAccount == linkedAccount;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    directoryId,
    directory,
    kind,
    name,
    Object.hashAll(roles),
    group,
    status,
    phone,
    email,
    address,
    website,
    worksAtContactId,
    linkedUserId,
    inactiveAt,
    legacyVetId,
    privateNote,
    householdNote,
    worksAt,
    Object.hashAll(staff),
    Object.hashAll(usageCounts.entries),
    linkedAccount,
  ]);
}

bool _rolesEq(List<ContactRole> a, List<ContactRole> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _staffEq(List<ContactStaffMember> a, List<ContactStaffMember> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEq(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}
