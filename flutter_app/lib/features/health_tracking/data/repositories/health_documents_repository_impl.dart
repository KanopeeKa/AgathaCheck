import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../domain/entities/health_document.dart';
import '../../domain/entities/health_entry_photo.dart';
import '../../domain/entities/health_issue_document.dart';
import '../../domain/repositories/health_documents_repository.dart';
import '../datasources/health_documents_remote.dart';

class HealthDocumentsRepositoryImpl implements HealthDocumentsRepository {
  HealthDocumentsRepositoryImpl({required this.baseUrl, required this.client});

  final String baseUrl;
  final http.Client client;

  @override
  Future<List<HealthDocument>> listEntryDocuments(
    String entryId, {
    String? occurrenceId,
  }) async {
    final rows = await fetchHealthEntryPhotosTransport(
      client: client,
      baseUrl: baseUrl,
      entryId: entryId,
      occurrenceId: occurrenceId,
    );
    return rows.map(_entryPhotoToDocument).toList();
  }

  @override
  Future<HealthDocument> uploadEntryDocument(
    String entryId,
    Uint8List bytes,
    String filename, {
    String caption = '',
    String? occurrenceId,
  }) async {
    final row = await postHealthEntryPhotoTransport(
      client: client,
      baseUrl: baseUrl,
      entryId: entryId,
      bytes: bytes,
      filename: filename,
      caption: caption,
      occurrenceId: occurrenceId,
    );
    return _entryPhotoToDocument(row);
  }

  @override
  Future<void> removeEntryDocument(String entryId, String documentId) {
    return deleteHealthEntryPhotoTransport(
      client: client,
      baseUrl: baseUrl,
      entryId: entryId,
      photoId: documentId,
    );
  }

  @override
  Future<List<HealthDocument>> listIssueDocuments(String issueId) async {
    final rows = await fetchHealthIssueDocumentsTransport(
      client: client,
      baseUrl: baseUrl,
      issueId: issueId,
    );
    return rows.map(_issueJsonToDocument).toList();
  }

  @override
  Future<HealthDocument> uploadIssueDocument(
    String issueId,
    Uint8List bytes,
    String filename,
    String mimeType,
  ) async {
    final row = await postHealthIssueDocumentTransport(
      client: client,
      baseUrl: baseUrl,
      issueId: issueId,
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
    return _issueJsonToDocument(row);
  }

  @override
  Future<void> removeIssueDocument(String issueId, String documentId) {
    return deleteHealthIssueDocumentTransport(
      client: client,
      baseUrl: baseUrl,
      issueId: issueId,
      documentId: documentId,
    );
  }

  HealthDocument _entryPhotoToDocument(HealthEntryPhoto row) {
    return HealthDocument(
      id: row.id,
      url: row.photoPath,
      healthEntryId: row.eventId,
      occurrenceId: row.occurrenceId,
      caption: row.caption,
    );
  }

  HealthDocument _issueJsonToDocument(Map<String, dynamic> json) {
    final doc = HealthIssueDocument.fromJson(json);
    return HealthDocument(
      id: doc.id,
      url: doc.url,
      healthIssueId: doc.healthIssueId,
    );
  }
}
