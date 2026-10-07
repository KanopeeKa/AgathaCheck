import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/app_logo_title.dart';
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
  String? _error;
  bool _accepting = false;

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
        _error = 'load_failed';
        _loading = false;
      });
    }
  }

  Future<void> _accept() async {
    if (ref.read(authProvider).accessToken == null) {
      if (!mounted) return;
      context.push(
        '/login?redirect=${Uri.encodeComponent('/absence-invite/${widget.inviteCode}')}',
      );
      return;
    }
    setState(() => _accepting = true);
    try {
      final ds = await _dataSource();
      await ds.acceptAbsenceCarerInvite(widget.inviteCode);
      if (!mounted) return;
      context.go('/pc/home');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _accepting = false;
        _error = 'accept_failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _preview == null) {
      return Scaffold(
        appBar: AppBar(title: const AppLogoTitle(title: 'Absence invite')),
        body: Center(child: Text(_error ?? 'Invitation unavailable')),
      );
    }
    final l = AppLocalizations.of(context)!;
    final inviter = _preview!['inviter_name'] as String? ?? 'Someone';
    final starts = _preview!['starts_on'] as String? ?? '';
    final ends = _preview!['ends_on'] as String? ?? '';
    final previewTitle = _preview!['title'] as String?;
    final absence = PlannedAbsence(
      id: 'preview',
      userId: 'preview',
      startsOn: starts,
      endsOn: ends,
      title: previewTitle,
      provenance: 'user_declared',
      status: 'active',
      petIds: const [],
    );
    final tripLabel = PlannedAbsenceDisplay.primaryLabel(l, absence);
    final secondaryDates = PlannedAbsenceDisplay.secondaryDateLine(l, absence);
    return Scaffold(
      appBar: AppBar(title: const AppLogoTitle(title: 'Absence invite')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$inviter invited you to help during an absence',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              tripLabel,
              style: Theme.of(context).textTheme.titleMedium,
              key: const Key('absence_invite_trip_label'),
            ),
            if (secondaryDates != null) ...[
              const SizedBox(height: 4),
              Text(secondaryDates),
            ],
            const Spacer(),
            FilledButton(
              key: const Key('absence_invite_accept'),
              onPressed: _accepting ? null : _accept,
              child: Text(_accepting ? 'Accepting…' : 'Accept invitation'),
            ),
          ],
        ),
      ),
    );
  }
}
