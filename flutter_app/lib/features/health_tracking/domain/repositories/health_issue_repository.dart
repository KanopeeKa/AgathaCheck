import '../entities/health_issue.dart';

abstract class HealthIssueRepository {
  Future<List<HealthIssue>> getIssues(String petId, String token);
  Future<HealthIssue> createIssue(HealthIssue issue, String token);
  Future<HealthIssue> updateIssue(HealthIssue issue, String token);
  Future<void> deleteIssue(String id, String token);
  Future<void> linkEvent(String issueId, String entryId, String token);
  Future<void> unlinkEvent(String issueId, String entryId, String token);
}
