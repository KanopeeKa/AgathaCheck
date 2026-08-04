import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/dashboard_section.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../experience/presentation/providers/experience_providers.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../domain/entities/member_privacy_settings.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/organization_member.dart';
import '../providers/member_privacy_providers.dart';
import '../providers/org_provider_list.dart';
import '../providers/org_provider_people.dart';
import '../widgets/member_privacy/member_privacy_fields.dart';

/// Account → per-organisation privacy + leave (D-v3-PRIV-1).
class AccountOrgSettingsScreen extends ConsumerStatefulWidget {
  const AccountOrgSettingsScreen({
    super.key,
    required this.orgId,
    this.highlightLeave = false,
  });

  final String orgId;
  final bool highlightLeave;

  @override
  ConsumerState<AccountOrgSettingsScreen> createState() =>
      _AccountOrgSettingsScreenState();
}

class _AccountOrgSettingsScreenState
    extends ConsumerState<AccountOrgSettingsScreen> {
  final _leaveSectionKey = GlobalKey();
  MemberPrivacySettings? _draft;

  @override
  void initState() {
    super.initState();
    if (widget.highlightLeave) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _leaveSectionKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
          );
        }
      });
    }
  }

  Organization? _orgForId(List<Organization> orgs) {
    for (final org in orgs) {
      if (org.id == widget.orgId) return org;
    }
    return null;
  }

  Future<void> _save(MemberPrivacySettings settings) async {
    final l = AppLocalizations.of(context)!;
    await ref.read(memberPrivacyProvider(widget.orgId).notifier).save(settings);
    if (!mounted) return;
    final error = ref.read(memberPrivacyProvider(widget.orgId)).error;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    setState(() => _draft = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.accountOrgPrivacySaved)));
  }

  Future<void> _confirmLeave(String orgName) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('account_org_leave_dialog'),
        title: Text(l.orgLeave),
        content: Text(l.orgLeaveConfirm),
        actions: [
          TextButton(
            key: const Key('account_org_leave_cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('account_org_leave_confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.orgLeave),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(orgMembersProvider(widget.orgId).notifier)
          .leaveOrganization();
      ref.invalidate(organizationListProvider);
      if (mounted) context.go('/account');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final experience = ref.watch(resolvedExperienceProvider);
    final orgsAsync = ref.watch(organizationListProvider);
    final privacyAsync = ref.watch(memberPrivacyProvider(widget.orgId));
    final org = orgsAsync.valueOrNull == null
        ? null
        : _orgForId(orgsAsync.valueOrNull!);
    final role = org == null ? null : OrgMemberRole.fromWire(org.role);

    return ExperienceShellScaffold(
      experience: experience,
      currentLocation: '/account/orgs/${widget.orgId}',
      screenTitle: org?.name ?? l.accountOrgSettingsTitle,
      child: privacyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (settings) {
          final draft = _draft ?? settings;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              DashboardSection(
                title: l.accountOrgPrivacySection,
                previewBuilder: (context) => MemberPrivacyFields(
                  settings: draft,
                  role: role,
                  onChanged: (next) => setState(() => _draft = next),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const Key('account_org_privacy_save'),
                  onPressed: () => _save(draft),
                  child: Text(l.save),
                ),
              ),
              const SizedBox(height: 24),
              DashboardSection(
                key: _leaveSectionKey,
                title: l.accountOrgLeaveSection,
                accentColor: Theme.of(context).colorScheme.error,
                previewBuilder: (context) => ListTile(
                  key: const Key('account_org_leave'),
                  leading: Icon(
                    Icons.exit_to_app,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    l.orgLeave,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  subtitle: Text(l.accountOrgLeaveSubtitle),
                  onTap: () => _confirmLeave(org?.name ?? ''),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
