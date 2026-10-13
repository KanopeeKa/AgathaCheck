import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/profile_completeness_kind.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/agatha_surface_policy.dart';

void main() {
  const policy = AgathaSurfacePolicy();
  final t0 = DateTime.utc(2026, 1, 1);
  final t15d = DateTime.utc(2026, 1, 16);
  final t31d = DateTime.utc(2026, 2, 1);

  test('AC-SP-01 tiebreak: rhythm beats welfare at equal severity', () {
    final picked = policy.pickProfileGuidance([
      AgathaGuidanceCandidate(
        kind: AgathaGuidanceKind.welfare,
        severity: 10,
        createdAt: t0,
        id: 'welfare-1',
      ),
      AgathaGuidanceCandidate(
        kind: AgathaGuidanceKind.rhythm,
        severity: 0,
        createdAt: t0,
        id: 'rhythm-1',
      ),
    ]);
    expect(picked?.id, 'rhythm-1');
  });

  test('AC-SP-01 tiebreak: higher welfare severity does not beat rhythm', () {
    final picked = policy.pickProfileGuidance([
      AgathaGuidanceCandidate(
        kind: AgathaGuidanceKind.welfare,
        severity: 99,
        createdAt: t0,
        id: 'welfare-high',
      ),
      AgathaGuidanceCandidate(
        kind: AgathaGuidanceKind.rhythm,
        severity: 0,
        createdAt: t31d,
        id: 'rhythm-newer',
      ),
    ]);
    expect(picked?.id, 'rhythm-newer');
  });

  test('AC-SP-01 tiebreak: among rhythm picks oldest created_at', () {
    final picked = policy.pickProfileGuidance([
      AgathaGuidanceCandidate(
        kind: AgathaGuidanceKind.rhythm,
        severity: 0,
        createdAt: t31d,
        id: 'newer',
      ),
      AgathaGuidanceCandidate(
        kind: AgathaGuidanceKind.rhythm,
        severity: 0,
        createdAt: t0,
        id: 'older',
      ),
    ]);
    expect(picked?.id, 'older');
  });

  test('AC-SP-02 completeness: 30d cooldown after dismiss with timestamp', () {
    expect(
      policy.shouldOfferCompletenessKind(
        kind: ProfileCompletenessKind.neuter,
        statusUnknown: true,
        dismissedOnPet: true,
        dismissedAt: t0,
        now: t15d,
      ),
      isFalse,
    );
    expect(
      policy.shouldOfferCompletenessKind(
        kind: ProfileCompletenessKind.neuter,
        statusUnknown: true,
        dismissedOnPet: true,
        dismissedAt: t0,
        now: t31d,
      ),
      isTrue,
    );
  });

  test(
    'AC-SP-02 completeness: server dismiss without local timestamp stays hidden',
    () {
      expect(
        policy.shouldOfferCompletenessKind(
          kind: ProfileCompletenessKind.chip,
          statusUnknown: true,
          dismissedOnPet: true,
          dismissedAt: null,
          now: t31d,
        ),
        isFalse,
      );
    },
  );
}
