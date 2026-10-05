import 'dart:typed_data';

import '../entities/health_document.dart';

abstract class HealthDocumentsRepository {
  Future<List<HealthDocument>> listEntryDocuments(
    String entryId, {
    String? occurrenceId,
  });

  Future<HealthDocument> uploadEntryDocument(
    String entryId,
    Uint8List bytes,
    String filename, {
    String caption = '',
    String? occurrenceId,
  });

  Future<void> removeEntryDocument(String entryId, String documentId);

  Future<List<HealthDocument>> listIssueDocuments(String issueId);

  Future<HealthDocument> uploadIssueDocument(
    String issueId,
    Uint8List bytes,
    String filename,
    String mimeType,
  );

  Future<void> removeIssueDocument(String issueId, String documentId);
}
