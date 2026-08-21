import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../data/datasources/organization_remote/organization_remote_context.dart';
import '../../../presentation/providers/org_provider_deps.dart';
import '../../../presentation/providers/org_provider_people.dart';
import '../../data/datasources/foster_home_visit_remote.dart';
import '../../data/repositories/foster_home_visit_repository_impl.dart';
import '../../domain/entities/foster_home_visit.dart';
import '../../domain/repositories/foster_home_visit_repository.dart';
import '../screens/foster_home_visit_admin_screen.dart';
import '../screens/foster_home_visit_status_screen.dart';

final fosterHomeVisitRemoteProvider = Provider<FosterHomeVisitRemote>((ref) {
  return FosterHomeVisitRemote(
    OrganizationRemoteContext(
      baseUrl: ref.watch(apiBaseUrlProvider),
      client: ref.watch(authHttpClientProvider),
    ),
  );
});

final fosterHomeVisitRepositoryProvider = Provider<FosterHomeVisitRepository>((
  ref,
) {
  return FosterHomeVisitRepositoryImpl(ref.watch(fosterHomeVisitRemoteProvider));
});

typedef FosterHomeVisitAdminKey = ({String orgId, String fosterParentId});

class FosterHomeVisitAdminNotifier
    extends FamilyAsyncNotifier<List<FosterHomeVisit>, FosterHomeVisitAdminKey> {
  @override
  Future<List<FosterHomeVisit>> build(FosterHomeVisitAdminKey key) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    return ref
        .read(fosterHomeVisitRepositoryProvider)
        .loadVisits(key.orgId, key.fosterParentId, token);
  }

  Future<FosterHomeVisit> scheduleVisit({
    required String visitDate,
    required String visitTime,
    String address = '',
    String notes = '',
  }) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    final visit = await ref
        .read(fosterHomeVisitRepositoryProvider)
        .scheduleVisit(
          arg.orgId,
          arg.fosterParentId,
          visitDate: visitDate,
          visitTime: visitTime,
          address: address,
          notes: notes,
          token: token,
        );
    ref.invalidateSelf();
    return visit;
  }

  Future<FosterHomeVisit> rescheduleVisit(
    String visitId, {
    required String visitDate,
    required String visitTime,
    String? address,
    String? notes,
  }) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    final visit = await ref
        .read(fosterHomeVisitRepositoryProvider)
        .rescheduleVisit(
          arg.orgId,
          visitId,
          visitDate: visitDate,
          visitTime: visitTime,
          address: address,
          notes: notes,
          token: token,
        );
    ref.invalidateSelf();
    return visit;
  }

  Future<FosterHomeVisit> cancelVisit(
    String visitId, {
    String cancelReason = '',
  }) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    final visit = await ref
        .read(fosterHomeVisitRepositoryProvider)
        .cancelVisit(
          arg.orgId,
          visitId,
          cancelReason: cancelReason,
          token: token,
        );
    ref.invalidateSelf();
    return visit;
  }

  Future<FosterHomeVisit> validateVisit(
    String visitId, {
    required String outcome,
    String outcomeReason = '',
  }) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    final visit = await ref
        .read(fosterHomeVisitRepositoryProvider)
        .validateVisit(
          arg.orgId,
          visitId,
          outcome: outcome,
          outcomeReason: outcomeReason,
          token: token,
        );
    ref.invalidateSelf();
    return visit;
  }
}

final fosterHomeVisitAdminProvider = AsyncNotifierProvider.family<
  FosterHomeVisitAdminNotifier,
  List<FosterHomeVisit>,
  FosterHomeVisitAdminKey
>(FosterHomeVisitAdminNotifier.new);

typedef FosterHomeVisitStatusKey = ({String orgId, String fosterParentId});

class FosterHomeVisitStatusNotifier
    extends
        FamilyAsyncNotifier<
          FosterHomeVisitStatusSnapshot,
          FosterHomeVisitStatusKey
        > {
  @override
  Future<FosterHomeVisitStatusSnapshot> build(
    FosterHomeVisitStatusKey key,
  ) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    return ref
        .read(fosterHomeVisitRepositoryProvider)
        .loadStatus(key.orgId, key.fosterParentId, token);
  }
}

final fosterHomeVisitStatusProvider = AsyncNotifierProvider.family<
  FosterHomeVisitStatusNotifier,
  FosterHomeVisitStatusSnapshot,
  FosterHomeVisitStatusKey
>(FosterHomeVisitStatusNotifier.new);

final fosterSelfParentIdProvider = Provider.family<String?, String>((ref, orgId) {
  final parentsAsync = ref.watch(orgFosterParentsProvider(orgId));
  return parentsAsync.maybeWhen(
    data: (parents) {
      for (final parent in parents) {
        if (parent.isSelfCard) return parent.id;
      }
      return null;
    },
    orElse: () => null,
  );
});

String fosterHomeVisitAdminRoutePath(String orgId, String fosterParentId) =>
    '/o/orgs/$orgId/foster-home-visits/$fosterParentId/admin';

String fosterHomeVisitStatusRoutePath(String orgId) =>
    '/o/orgs/$orgId/foster-home-visit/status';

List<RouteBase> buildFosterHomeVisitRoutes() {
  return [
    GoRoute(
      path: 'foster-home-visits/:fosterParentId/admin',
      name: 'fosterHomeVisitAdmin',
      builder: (context, state) {
        final orgId = state.pathParameters['id']!;
        final fosterParentId = state.pathParameters['fosterParentId']!;
        return FosterHomeVisitAdminScreen(
          orgId: orgId,
          fosterParentId: fosterParentId,
        );
      },
    ),
    GoRoute(
      path: 'foster-home-visit/status',
      name: 'fosterHomeVisitStatus',
      builder: (context, state) {
        final orgId = state.pathParameters['id']!;
        return FosterHomeVisitStatusScreen(orgId: orgId);
      },
    ),
  ];
}

String localizedFosterHomeVisitStatusLabel(dynamic l, FosterHomeVisitStatus status) {
  return switch (status) {
    FosterHomeVisitStatus.scheduled => l.fosterHomeVisitStatusScheduled,
    FosterHomeVisitStatus.cancelled => l.fosterHomeVisitStatusCancelled,
    FosterHomeVisitStatus.validated => l.fosterHomeVisitStatusValidated,
  };
}

String localizedFosterHomeVisitOutcomeLabel(
  dynamic l,
  FosterHomeVisitOutcome outcome,
) {
  return switch (outcome) {
    FosterHomeVisitOutcome.yes => l.fosterHomeVisitOutcomeYes,
    FosterHomeVisitOutcome.no => l.fosterHomeVisitOutcomeNo,
  };
}

String formatFosterHomeVisitDateTime(String visitDate, String? visitTime) {
  final parsed = DateTime.tryParse(visitDate);
  final dateLabel = parsed != null
      ? '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}'
      : visitDate;
  if (visitTime == null || visitTime.isEmpty) return dateLabel;
  return '$dateLabel · $visitTime';
}
