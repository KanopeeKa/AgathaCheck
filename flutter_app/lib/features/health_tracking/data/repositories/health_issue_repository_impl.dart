import '../../domain/entities/health_issue.dart';
import '../../domain/entities/health_issue_document.dart';
import '../../domain/repositories/health_issue_repository.dart';
import '../datasources/health_issue_remote_datasource.dart';
import '../models/health_issue_model.dart';

class HealthIssueRepositoryImpl implements HealthIssueRepository {
  const HealthIssueRepositoryImpl(this.dataSource);

  final HealthIssueRemoteDataSource dataSource;

  @override
  Future<List<HealthIssue>> getIssues(String petId, String token) {
    return dataSource.getIssues(petId, token);
  }

  @override
  Future<HealthIssue> createIssue(HealthIssue issue, String token) {
    return dataSource.createIssue(HealthIssueModel.fromEntity(issue), token);
  }

  @override
  Future<HealthIssue> updateIssue(HealthIssue issue, String token) {
    return dataSource.updateIssue(HealthIssueModel.fromEntity(issue), token);
  }

  @override
  Future<void> deleteIssue(String id, String token) {
    return dataSource.deleteIssue(id, token);
  }

  @override
  Future<void> linkEvent(String issueId, String entryId, String token) {
    return dataSource.linkEvent(issueId, entryId, token);
  }

  @override
  Future<void> unlinkEvent(String issueId, String entryId, String token) {
    return dataSource.unlinkEvent(issueId, entryId, token);
  }

  @override
  Future<List<HealthIssueDocument>> getDocuments(
    String issueId,
    String token,
  ) async {
    final rows = await dataSource.getDocuments(issueId, token);
    return rows.map(HealthIssueDocument.fromJson).toList();
  }

  @override
  Future<HealthIssueDocument> uploadDocument(
    String issueId,
    List<int> bytes,
    String filename,
    String mimeType,
    String token,
  ) async {
    final row = await dataSource.uploadDocument(
      issueId,
      bytes,
      filename,
      mimeType,
      token,
    );
    return HealthIssueDocument.fromJson(row);
  }

  @override
  Future<void> deleteDocument(
    String issueId,
    String documentId,
    String token,
  ) {
    return dataSource.deleteDocument(issueId, documentId, token);
  }
}
