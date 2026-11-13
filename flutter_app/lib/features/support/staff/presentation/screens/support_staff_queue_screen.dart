import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../features/auth/auth.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../data/support_staff_api.dart';

class SupportStaffQueueScreen extends ConsumerStatefulWidget {
  const SupportStaffQueueScreen({super.key});

  @override
  ConsumerState<SupportStaffQueueScreen> createState() =>
      _SupportStaffQueueScreenState();
}

class _SupportStaffQueueScreenState extends ConsumerState<SupportStaffQueueScreen> {
  List<SupportStaffTicketSummary>? _tickets;
  String? _error;
  bool _loading = true;
  bool _forbidden = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final token = ref.read(authProvider).accessToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _forbidden = false;
        _tickets = const [];
      });
      return;
    }

    final api = SupportStaffApi(
      baseUrl: ref.read(apiBaseUrlProvider),
      accessToken: token,
    );
    try {
      final tickets = await api.listTickets();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
        _error = null;
        _forbidden = false;
      });
    } on SupportStaffApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _forbidden = e.isForbidden;
        _error = e.isForbidden ? null : e.message;
        _tickets = const [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'load_error';
        _tickets = const [];
      });
    } finally {
      api.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: AppLogoTitle(title: l.supportStaffQueueTitle)),
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        child: _buildBody(context, l, theme),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l, ThemeData theme) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_forbidden) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l.supportStaffQueueForbidden,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l.supportStaffQueueLoadError,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      );
    }

    final tickets = _tickets ?? const [];
    if (tickets.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l.supportStaffQueueEmpty,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return ListTile(
          title: Text('${ticket.reference} · ${ticket.title}'),
          subtitle: Text(
            '${ticket.category} · ${ticket.reporterEmail}',
          ),
          trailing: ticket.outboxAlerts.isEmpty
              ? null
              : Tooltip(
                  message: l.supportStaffOutboxAlertTooltip,
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                  ),
                ),
          onTap: () => context.push('/staff/support/${ticket.id}'),
        );
      },
    );
  }
}
