import '../../domain/entities/health_issue.dart';
import '../../domain/repositories/health_issue_repository.dart';
import '../datasources/health_issue_remote_datasource.dart';
import '../models/health_issue_model.dart';

class HealthIssueRepositoryImpl implements HealthIssueRepository {
  const HealthIssueRepositoryImpl(this.dataSource);

  final HealthIssueRemoteDataSource dataSource;

  @override
  Future<List<HealthIssue>> getIssues(String petId) {
    return dataSource.getIssues(petId);
  }

  @override
  Future<HealthIssue> createIssue(HealthIssue issue) {
    return dataSource.createIssue(HealthIssueModel.fromEntity(issue));
  }

  @override
  Future<HealthIssue> updateIssue(HealthIssue issue) {
    return dataSource.updateIssue(HealthIssueModel.fromEntity(issue));
  }

  @override
  Future<void> deleteIssue(String id) {
    return dataSource.deleteIssue(id);
  }

  @override
  Future<void> linkEvent(String issueId, String entryId) {
    return dataSource.linkEvent(issueId, entryId);
  }

  @override
  Future<void> unlinkEvent(String issueId, String entryId) {
    return dataSource.unlinkEvent(issueId, entryId);
  }
}
