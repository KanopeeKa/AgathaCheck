import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/about/domain/legal_document_id.dart';

void main() {
  group('LegalDocumentId', () {
    test('routePath and assetPathForLocale', () {
      expect(LegalDocumentId.termsOfUse.routePath, '/legal/terms-of-use');
      expect(
        LegalDocumentId.privacyNotice.assetPathForLocale('en'),
        'assets/legal/en/privacy-notice.md',
      );
      expect(
        LegalDocumentId.privacyNotice.assetPathForLocale('fr-CA'),
        'assets/legal/fr/politique-de-confidentialite.md',
      );
      expect(
        LegalDocumentId.dataProcessingAddendum.assetPathForLocale('en'),
        'assets/legal/en/dpa.md',
      );
    });

    test('fromRouteSegment resolves known segments', () {
      expect(
        LegalDocumentId.fromRouteSegment('terms-of-use'),
        LegalDocumentId.termsOfUse,
      );
      expect(LegalDocumentId.fromRouteSegment('dpa'), LegalDocumentId.dataProcessingAddendum);
      expect(LegalDocumentId.fromRouteSegment('unknown'), isNull);
    });
  });
}
