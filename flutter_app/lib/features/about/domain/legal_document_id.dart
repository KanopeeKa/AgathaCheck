enum LegalDocumentId {
  termsOfUse,
  privacyNotice,
  legalNotice,
  dataProcessingAddendum;

  String get routePath => switch (this) {
        LegalDocumentId.termsOfUse => '/legal/terms-of-use',
        LegalDocumentId.privacyNotice => '/legal/privacy-notice',
        LegalDocumentId.legalNotice => '/legal/legal-notice',
        LegalDocumentId.dataProcessingAddendum => '/legal/dpa',
      };

  String assetPathForLocale(String languageCode) {
    final locale = languageCode.startsWith('fr') ? 'fr' : 'en';
    return switch (this) {
      LegalDocumentId.termsOfUse => locale == 'fr'
          ? 'assets/legal/fr/conditions-dutilisation.md'
          : 'assets/legal/en/terms-of-use.md',
      LegalDocumentId.privacyNotice => locale == 'fr'
          ? 'assets/legal/fr/politique-de-confidentialite.md'
          : 'assets/legal/en/privacy-notice.md',
      LegalDocumentId.legalNotice => locale == 'fr'
          ? 'assets/legal/fr/mentions-legales.md'
          : 'assets/legal/en/legal-notice.md',
      LegalDocumentId.dataProcessingAddendum =>
        'assets/legal/$locale/dpa.md',
    };
  }

  static LegalDocumentId? fromRouteSegment(String segment) {
    return switch (segment) {
      'terms-of-use' => LegalDocumentId.termsOfUse,
      'privacy-notice' => LegalDocumentId.privacyNotice,
      'legal-notice' => LegalDocumentId.legalNotice,
      'dpa' => LegalDocumentId.dataProcessingAddendum,
      _ => null,
    };
  }

  static const publicRoutes = [
    '/legal',
    '/legal/terms-of-use',
    '/legal/privacy-notice',
    '/legal/legal-notice',
    '/legal/dpa',
    '/privacy-policy',
    '/terms-of-service',
    '/about',
  ];
}
