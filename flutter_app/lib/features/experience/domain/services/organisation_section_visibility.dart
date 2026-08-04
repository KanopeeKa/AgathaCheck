/// Visibility rules for the Organisation drawer entry and section access (D-v3-VIS-1).
class OrganisationSectionVisibility {
  const OrganisationSectionVisibility._();

  /// Whether the Organisation drawer item should appear.
  static bool showInDrawer({
    required bool showOrganisationSectionPref,
    required bool hasOrgMembership,
  }) =>
      showOrganisationSectionPref || hasOrgMembership;

  /// Toggle is interactive only when the user has no org memberships.
  static bool toggleEnabled({required bool hasOrgMembership}) => !hasOrgMembership;

  /// Effective toggle value (members are always shown).
  static bool effectiveShowOrganisationSection({
    required bool showOrganisationSectionPref,
    required bool hasOrgMembership,
  }) => hasOrgMembership || showOrganisationSectionPref;

  /// Whether the user may open the organisation section (login routing, drawer nav).
  static bool canAccessOrganizationSection({
    required bool hasOrgMembership,
    required bool showOrganisationSectionPref,
  }) => hasOrgMembership || showOrganisationSectionPref;
}
