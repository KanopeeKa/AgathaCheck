import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../features/auth/auth.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../data/support_staff_api.dart';

class SupportStaffTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportStaffTicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<SupportStaffTicketDetailScreen> createState() =>
      _SupportStaffTicketDetailScreenState();
}

class _SupportStaffTicketDetailScreenState
    extends ConsumerState<SupportStaffTicketDetailScreen> {
  SupportStaffTicketDetailResponse? _detail;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final token = ref.read(authProvider).accessToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'unauthorized';
      });
      return;
    }

    final api = SupportStaffApi(
      baseUrl: ref.read(apiBaseUrlProvider),
      accessToken: token,
    );
    try {
      final detail = await api.getTicket(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _error = null;
      });
    } on SupportStaffApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'load_error';
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
      appBar: AppBar(title: AppLogoTitle(title: l.supportStaffTicketDetailTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l.supportStaffQueueLoadError,
                style: theme.textTheme.bodyLarge,
              ),
            )
          : _buildDetail(context, l, theme),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    AppLocalizations l,
    ThemeData theme,
  ) {
    final detail = _detail;
    if (detail == null) {
      return const SizedBox.shrink();
    }
    final ticket = detail.ticket;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          ticket.reference,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          ticket.title,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(
          l.supportStaffReporterLine(ticket.reporterEmail),
          style: theme.textTheme.bodyMedium,
        ),
        if (ticket.githubIssueNumber != null) ...[
          const SizedBox(height: 8),
          Text(l.supportStaffGitHubIssue(ticket.githubIssueNumber!)),
        ],
        const SizedBox(height: 24),
        Text(l.supportStaffDescriptionHeading, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(ticket.description),
        if (ticket.expected != null && ticket.expected!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l.supportFormExpectedLabel, style: theme.textTheme.titleSmall),
          Text(ticket.expected!),
        ],
        if (ticket.actual != null && ticket.actual!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l.supportFormActualLabel, style: theme.textTheme.titleSmall),
          Text(ticket.actual!),
        ],
        if (ticket.steps != null && ticket.steps!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l.supportFormStepsLabel, style: theme.textTheme.titleSmall),
          Text(ticket.steps!),
        ],
        const SizedBox(height: 24),
        Text(l.supportStaffOutboxSection, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (detail.outbox.isEmpty)
          Text(
            l.supportStaffOutboxEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...detail.outbox.map(
            (row) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${row.kind} · ${row.status}',
                      style: theme.textTheme.titleSmall,
                    ),
                    if (row.lastError != null && row.lastError!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          row.lastError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(l.supportStaffAttachmentsSection, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (detail.attachments.isEmpty)
          Text(
            l.supportStaffAttachmentsEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...detail.attachments.map(
            (file) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(file.mime),
              subtitle: Text(l.supportStaffAttachmentBytes(file.bytes)),
            ),
          ),
      ],
    );
  }
}
