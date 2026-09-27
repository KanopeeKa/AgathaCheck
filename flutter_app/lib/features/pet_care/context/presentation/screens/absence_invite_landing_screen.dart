import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/care_context_remote_datasource.dart';
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
        appBar: AppBar(title: const AppLogoTitle()),
        body: Center(child: Text(_error ?? 'Invitation unavailable')),
      );
    }
    final inviter = _preview!['inviter_name'] as String? ?? 'Someone';
    final starts = _preview!['starts_on'] as String? ?? '';
    final ends = _preview!['ends_on'] as String? ?? '';
    return Scaffold(
      appBar: AppBar(title: const AppLogoTitle()),
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
            Text('Access window: $starts through $ends (local days).'),
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
