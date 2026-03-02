import '../entities/health_issue.dart';

abstract class HealthIssueRepository {
  Future<List<HealthIssue>> getIssues(String petId);
  Future<HealthIssue> createIssue(HealthIssue issue);
  Future<HealthIssue> updateIssue(HealthIssue issue);
  Future<void> deleteIssue(String id);
  Future<void> linkEvent(String issueId, String entryId);
  Future<void> unlinkEvent(String issueId, String entryId);
}
