import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:go_router/go_router.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/organization_member.dart';
import '../../../../domain/services/org_permissions.dart';
import '../../../../presentation/providers/org_provider_list.dart';
import '../providers/foster_questionnaire_review_providers.dart';
import '../screens/foster_questionnaire_review_screen.dart';

/// Entry point for admins to open the foster questionnaire review screen.
class FosterQuestionnaireReviewLink extends ConsumerWidget {
  const FosterQuestionnaireReviewLink({
    super.key,
    required this.orgId,
    required this.fosterParentId,
  });

  final String orgId;
  final String fosterParentId;

  bool _canReview(WidgetRef ref) {
    final org = ref
        .watch(organizationListProvider)
        .valueOrNull
        ?.where((item) => item.id == orgId)
        .firstOrNull;
    if (org?.role == null) return false;
    return hasPermission(
      OrgMemberRole.fromWire(org!.role!),
      orgId,
      'review_foster_onboarding',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_canReview(ref)) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      key: const Key('foster_questionnaire_review_link'),
      onPressed: () => context.push(
        fosterQuestionnaireReviewRoutePath(orgId, fosterParentId),
      ),
      icon: const Icon(Icons.fact_check_outlined, size: 18),
      label: Text(l.fosterQuestionnaireReviewLink),
    );
  }
}

/// Route registration for integration into org management routes.
GoRoute buildFosterQuestionnaireReviewRoute() {
  return GoRoute(
    path: 'foster-questionnaire/:fosterParentId/review',
    name: 'fosterQuestionnaireReview',
    builder: (context, state) {
      final orgId = state.pathParameters['id']!;
      final fosterParentId = state.pathParameters['fosterParentId']!;
      return FosterQuestionnaireReviewScreen(
        orgId: orgId,
        fosterParentId: fosterParentId,
      );
    },
  );
}
