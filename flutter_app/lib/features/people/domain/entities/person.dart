import 'household.dart';
import 'household_invite.dart';
import 'contact_summary.dart';

sealed class Person {
  const Person();
}

final class ContactPerson extends Person {
  const ContactPerson(this.summary);
  final ContactSummary summary;

  String get id => summary.id;

  @override
  bool operator ==(Object other) {
    return other is ContactPerson && other.summary == summary;
  }

  @override
  int get hashCode => summary.hashCode;
}

final class HouseholdMemberPerson extends Person {
  const HouseholdMemberPerson({required this.household, required this.member});

  final Household household;
  final HouseholdMember member;

  String get id => member.userId;

  @override
  bool operator ==(Object other) {
    return other is HouseholdMemberPerson &&
        other.household == household &&
        other.member == member;
  }

  @override
  int get hashCode => Object.hash(household, member);
}

final class PendingInvitePerson extends Person {
  const PendingInvitePerson(this.invite);
  final HouseholdInvite invite;

  String get id => invite.id;

  @override
  bool operator ==(Object other) {
    return other is PendingInvitePerson && other.invite == invite;
  }

  @override
  int get hashCode => invite.hashCode;
}
