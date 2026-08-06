import '../../../domain/entities/organization_member.dart';
import '../../../domain/services/org_permissions.dart';

enum TriState { on, off, indeterminate }

class MemberPermissionBaseline {
  const MemberPermissionBaseline({
    required this.role,
    required this.effective,
    required this.overrides,
  });

  final OrgMemberRole role;
  final Set<String> effective;
  final Set<String> overrides;

  factory MemberPermissionBaseline.fromApi(Map<String, dynamic> data) {
    final roleName = data['role'] as String? ?? 'associate';
    final overrides = (data['overrides'] as List? ?? [])
        .map((row) => (row as Map<String, dynamic>)['permission_key'] as String)
        .toSet();
    final effective = (data['effective_permissions'] as List? ?? [])
        .cast<String>()
        .toSet();
    return MemberPermissionBaseline(
      role: OrgMemberRole.fromWire(roleName),
      effective: effective,
      overrides: overrides,
    );
  }
}

class StagedPermissionsController {
  const StagedPermissionsController({
    required this.baselines,
    this.staged = const {},
  });

  final Map<String, MemberPermissionBaseline> baselines;
  final Map<String, bool> staged;

  static String stagedKey(String userId, String permissionKey) =>
      '$userId|$permissionKey';

  bool effectiveForUser(String userId, String permissionKey) {
    final stagedValue = staged[stagedKey(userId, permissionKey)];
    if (stagedValue != null) return stagedValue;
    return baselines[userId]?.effective.contains(permissionKey) ?? false;
  }

  bool hasPendingChange(String permissionKey, Iterable<String> userIds) {
    for (final userId in userIds) {
      final key = stagedKey(userId, permissionKey);
      if (!staged.containsKey(key)) continue;
      final baselineEffective =
          baselines[userId]?.effective.contains(permissionKey) ?? false;
      if (staged[key] != baselineEffective) return true;
    }
    return false;
  }

  TriState aggregateState(String permissionKey, Iterable<String> userIds) {
    bool? value;
    for (final userId in userIds) {
      final effective = effectiveForUser(userId, permissionKey);
      if (value == null) {
        value = effective;
      } else if (value != effective) {
        return TriState.indeterminate;
      }
    }
    return value == true ? TriState.on : TriState.off;
  }

  bool isRoleDefaultOnly(String userId, String permissionKey) {
    final baseline = baselines[userId];
    if (baseline == null) return false;
    return baseline.effective.contains(permissionKey) &&
        !baseline.overrides.contains(permissionKey);
  }

  bool canToggleKey(String permissionKey, Iterable<String> userIds) {
    for (final userId in userIds) {
      if (!isRoleDefaultOnly(userId, permissionKey)) return true;
    }
    return false;
  }

  StagedPermissionsController stageToggle(
    String permissionKey,
    Iterable<String> userIds,
    bool granted,
  ) {
    final next = Map<String, bool>.from(staged);
    for (final userId in userIds) {
      final baseline = baselines[userId];
      if (baseline == null) continue;
      if (isRoleDefaultOnly(userId, permissionKey) && !granted) continue;

      final serverEffective = baseline.effective.contains(permissionKey);
      final key = stagedKey(userId, permissionKey);
      if (granted == serverEffective) {
        next.remove(key);
      } else {
        next[key] = granted;
      }
    }
    return StagedPermissionsController(baselines: baselines, staged: next);
  }

  StagedPermissionsController applyRolePreset(
    OrgMemberRole role,
    Iterable<String> userIds,
  ) {
    final tierKeys = g0PermissionKeysForRole(role);
    final next = Map<String, bool>.from(staged);
    for (final userId in userIds) {
      final baseline = baselines[userId];
      if (baseline == null) continue;
      for (final key in orderedPermissionKeys) {
        final desired = tierKeys.contains(key);
        final serverEffective = baseline.effective.contains(key);
        final keyId = stagedKey(userId, key);
        if (desired == serverEffective) {
          next.remove(keyId);
          continue;
        }
        if (!desired && isRoleDefaultOnly(userId, key)) {
          next.remove(keyId);
          continue;
        }
        next[keyId] = desired;
      }
    }
    return StagedPermissionsController(baselines: baselines, staged: next);
  }

  List<Map<String, dynamic>> buildSaveChanges() {
    final changes = <Map<String, dynamic>>[];
    for (final entry in staged.entries) {
      final separator = entry.key.indexOf('|');
      if (separator <= 0) continue;
      final userId = entry.key.substring(0, separator);
      final permissionKey = entry.key.substring(separator + 1);
      final desired = entry.value;
      final baseline = baselines[userId];
      if (baseline == null) continue;
      final serverEffective = baseline.effective.contains(permissionKey);
      if (desired == serverEffective) continue;
      if (desired) {
        changes.add({
          'user_id': userId,
          'permission_key': permissionKey,
          'granted': true,
        });
      } else if (baseline.overrides.contains(permissionKey)) {
        changes.add({
          'user_id': userId,
          'permission_key': permissionKey,
          'granted': false,
        });
      }
    }
    return changes;
  }

  bool get hasUnsavedChanges => buildSaveChanges().isNotEmpty;

  StagedPermissionsController clearStaged() =>
      StagedPermissionsController(baselines: baselines);
}
