import 'package:flutter/material.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/legal_document_loader.dart';
import '../../domain/legal_document_id.dart';
import '../widgets/legal_document_body.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.documentId});

  final LegalDocumentId documentId;

  String _title(AppLocalizations l10n) => switch (documentId) {
    LegalDocumentId.termsOfUse => l10n.termsOfService,
    LegalDocumentId.privacyNotice => l10n.privacyPolicy,
    LegalDocumentId.legalNotice => l10n.legalNotice,
    LegalDocumentId.dataProcessingAddendum => l10n.dataProcessingAddendum,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    const loader = LegalDocumentLoader();

    return Scaffold(
      appBar: AppBar(title: AppLogoTitle(title: _title(l10n))),
      body: FutureBuilder<String>(
        future: loader.load(documentId: documentId, languageCode: locale),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.legalDocumentLoadError),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: LegalDocumentBody(markdown: snapshot.data ?? ''),
              ),
            ),
          );
        },
      ),
    );
  }
}
