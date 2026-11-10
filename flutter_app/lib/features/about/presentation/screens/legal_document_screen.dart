import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/async_state/async_error_state.dart';
import '../../../../core/widgets/async_state/labelled_progress.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/legal_document_loader.dart';
import '../../domain/legal_document_id.dart';
import '../widgets/legal_document_body.dart';

class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key, required this.documentId});

  final LegalDocumentId documentId;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  static const _loader = LegalDocumentLoader();
  Future<String>? _documentFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _documentFuture ??= _loadDocument();
  }

  Future<String> _loadDocument() {
    final locale = Localizations.localeOf(context).languageCode;
    return _loader.load(documentId: widget.documentId, languageCode: locale);
  }

  void _retry() {
    setState(() {
      _documentFuture = _loadDocument();
    });
  }

  String _title(AppLocalizations l10n) => switch (widget.documentId) {
    LegalDocumentId.termsOfUse => l10n.termsOfService,
    LegalDocumentId.privacyNotice => l10n.privacyPolicy,
    LegalDocumentId.legalNotice => l10n.legalNotice,
    LegalDocumentId.dataProcessingAddendum => l10n.dataProcessingAddendum,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: AppLogoTitle(title: _title(l10n))),
      body: FutureBuilder<String>(
        future: _documentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: LabelledProgress(label: l10n.loadingLabel));
          }

          if (snapshot.hasError) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  AsyncErrorState(
                    title: l10n.legalDocumentLoadError,
                    onRetry: _retry,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: TextButton(
                      onPressed: () => context.go('/legal'),
                      child: Text(l10n.viewAllLegalDocuments),
                    ),
                  ),
                ],
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
