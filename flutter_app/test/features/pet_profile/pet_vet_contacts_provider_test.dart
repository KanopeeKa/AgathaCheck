import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/providers/pet_vet_contacts_provider.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';

void main() {
  test('petVetOptionsFromRoster maps linked vet record ids', () {
    const roster = Roster(
      households: const [],
      pendingInvites: const [],
      contacts: [
        ContactSummary(
          id: 'c1',
          directory: ContactDirectoryRef(type: 'personal'),
          kind: ContactKind.organisation,
          name: 'Greenhill Vet',
          roles: [ContactRole.vet],
          group: ContactGroup.professional,
          status: ContactStatus.active,
          linkedVetRecordId: 'vet-1',
        ),
      ],
    );
    final options = petVetOptionsFromRoster(roster);
    expect(options, hasLength(1));
    expect(options.first.vetId, 'vet-1');
    expect(options.first.displayName, 'Greenhill Vet');
  });
}
