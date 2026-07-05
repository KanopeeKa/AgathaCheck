import 'package:flutter/services.dart';

import '../domain/legal_document_id.dart';

class LegalDocumentLoader {
  const LegalDocumentLoader();

  Future<String> load({
    required LegalDocumentId documentId,
    required String languageCode,
  }) async {
    final assetPath = documentId.assetPathForLocale(languageCode);
    return rootBundle.loadString(assetPath);
  }
}
