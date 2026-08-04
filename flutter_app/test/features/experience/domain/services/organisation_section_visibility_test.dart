import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/domain/services/organisation_section_visibility.dart';

void main() {
  group('OrganisationSectionVisibility', () {
    test('non-member with toggle off hides drawer entry', () {
      expect(
        OrganisationSectionVisibility.showInDrawer(
          showOrganisationSectionPref: false,
          hasOrgMembership: false,
        ),
        isFalse,
      );
      expect(
        OrganisationSectionVisibility.effectiveShowOrganisationSection(
          showOrganisationSectionPref: false,
          hasOrgMembership: false,
        ),
        isFalse,
      );
      expect(
        OrganisationSectionVisibility.toggleEnabled(hasOrgMembership: false),
        isTrue,
      );
    });

    test('non-member with toggle on shows drawer entry', () {
      expect(
        OrganisationSectionVisibility.showInDrawer(
          showOrganisationSectionPref: true,
          hasOrgMembership: false,
        ),
        isTrue,
      );
      expect(
        OrganisationSectionVisibility.canAccessOrganizationSection(
          hasOrgMembership: false,
          showOrganisationSectionPref: true,
        ),
        isTrue,
      );
    });

    test('member forces show on, disables toggle, shows drawer', () {
      expect(
        OrganisationSectionVisibility.showInDrawer(
          showOrganisationSectionPref: false,
          hasOrgMembership: true,
        ),
        isTrue,
      );
      expect(
        OrganisationSectionVisibility.effectiveShowOrganisationSection(
          showOrganisationSectionPref: false,
          hasOrgMembership: true,
        ),
        isTrue,
      );
      expect(
        OrganisationSectionVisibility.toggleEnabled(hasOrgMembership: true),
        isFalse,
      );
      expect(
        OrganisationSectionVisibility.canAccessOrganizationSection(
          hasOrgMembership: true,
          showOrganisationSectionPref: false,
        ),
        isTrue,
      );
    });

    test('member with toggle pref on stays on', () {
      expect(
        OrganisationSectionVisibility.effectiveShowOrganisationSection(
          showOrganisationSectionPref: true,
          hasOrgMembership: true,
        ),
        isTrue,
      );
    });
  });
}
