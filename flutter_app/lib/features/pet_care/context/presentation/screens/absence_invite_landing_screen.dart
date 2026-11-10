import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../core/widgets/invite_recipient_block.dart';
import 'package:pet_profile_app/features/auth/auth.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import '../../data/datasources/care_context_remote_datasource.dart';
import '../../domain/entities/planned_absence.dart';
import '../planned_absence_display.dart';
import '../providers/care_context_providers.dart';

/// Landing screen for absence carer invites at `/absence-invite/:code`.
class AbsenceInviteLandingScreen extends ConsumerStatefulWidget {
  const AbsenceInviteLandingScreen({super.key, required this.inviteCode});

  final String inviteCode;

  @override
  ConsumerState<AbsenceInviteLandingScreen> createState() =>
      _AbsenceInviteLandingScreenState();
}

class _AbsenceInviteLandingScreenState
    extends ConsumerState<AbsenceInviteLandingScreen> {
  Map<String, dynamic>? _preview;
  bool _loading = true;
  String? _loadErrorKey;
  bool _accepting = false;
  bool _acceptFailed = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<CareContextRemoteDataSource> _dataSource() async {
    final ds = ref.read(careContextRemoteDataSourceProvider);
    final token = ref.read(authProvider).accessToken;
    ds.authToken = token;
    return ds;
  }

  Future<void> _loadPreview() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadErrorKey = null;
      _preview = null;
      _acceptFailed = false;
    });
    try {
      final ds = await _dataSource();
      final preview = await ds.fetchAbsenceCarerInvitePreview(
        widget.inviteCode,
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadErrorKey = 'load_failed';
        _loading = false;
      });
    }
  }

  Future<void> _accept() async {
    setState(() {
      _accepting = true;
      _acceptFailed = false;
    });
    try {
      final ds = await _dataSource();
      await ds.acceptAbsenceCarerInvite(widget.inviteCode);
      if (!mounted) return;
      context.go('/pc/home');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _accepting = false;
        _acceptFailed = true;
      });
    }
  }

  PlannedAbsence? _absenceFromPreview(Map<String, dynamic> preview) {
    final starts = preview['starts_on'] as String? ?? '';
    final ends = preview['ends_on'] as String? ?? '';
    if (starts.isEmpty && ends.isEmpty) return null;
    return PlannedAbsence(
      id: 'preview',
      userId: 'preview',
      startsOn: starts,
      endsOn: ends,
      title: preview['title'] as String?,
      provenance: 'user_declared',
      status: 'active',
      petIds: const [],
    );
  }

  String _inviterDisplay(AppLocalizations l, Map<String, dynamic> preview) {
    final raw = preview['inviter_name'] as String?;
    if (raw != null && raw.trim().isNotEmpty) return raw.trim();
    return l.sharedPetLinkIdentityUnavailable;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    final invitePath = '/absence-invite/${widget.inviteCode}';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l.absenceInviteTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadErrorKey == 'load_failed') {
      return Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l.absenceInviteTitle)),
        body: AsyncErrorState(
          title: l.absenceInviteLoadFailed,
          onRetry: _loadPreview,
        ),
      );
    }

    if (_preview == null) {
      return Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l.absenceInviteTitle)),
        body: Center(
          child: Text(
            l.absenceInviteUnavailable,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final preview = _preview!;
    final inviter = _inviterDisplay(l, preview);
    final absence = _absenceFromPreview(preview);
    final tripLabel = absence != null
        ? PlannedAbsenceDisplay.primaryLabel(l, absence)
        : null;
    final secondaryDates = absence != null
        ? PlannedAbsenceDisplay.secondaryDateLine(l, absence)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: l.absenceInviteTitle),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: l.goToPetCare,
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isLoggedIn)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.absenceInviteHeadline(inviter),
                      style: theme.textTheme.titleLarge,
                    ),
                    if (tripLabel != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        tripLabel,
                        style: theme.textTheme.titleMedium,
                        key: const Key('absence_invite_trip_label'),
                      ),
                    ],
                    if (secondaryDates != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        secondaryDates,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else ...[
            InviteRecipientBlock(
              invitePath: invitePath,
              scopeDescription: l.absenceInviteAccessScope,
              inviterName: preview['inviter_name'] as String?,
            ),
            if (tripLabel != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tripLabel,
                        style: theme.textTheme.titleMedium,
                        key: const Key('absence_invite_trip_label'),
                      ),
                      if (secondaryDates != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          secondaryDates,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
          if (isLoggedIn) ...[
            const SizedBox(height: 16),
            if (_acceptFailed)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l.absenceInviteAcceptFailed,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            FilledButton(
              key: const Key('absence_invite_accept'),
              onPressed: _accepting ? null : _accept,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                _accepting ? l.absenceInviteAccepting : l.absenceInviteAccept,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
