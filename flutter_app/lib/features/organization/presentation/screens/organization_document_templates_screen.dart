import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/org_permissions_providers.dart';
import '../utils/org_screen_theme.dart';

class OrganizationDocumentTemplatesScreen extends ConsumerWidget {
  const OrganizationDocumentTemplatesScreen({super.key, required this.orgId});

  final String orgId;

  List<Map<String, dynamic>> _templatesFor(
    Map<String, dynamic> data,
    String key,
  ) {
    final raw = data[key];
    if (raw is! List) return const [];
    return raw.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(documentTemplatesProvider(orgId));
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return orgThemed(
      child: Scaffold(
        appBar: AppBar(
          title: AppLogoTitle(title: l.orgCustomisationsTemplatesTitle),
          leading: IconButton(
            key: const Key('org_document_templates_back'),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.pop(),
          ),
        ),
        body: templatesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('$e'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(documentTemplatesProvider(orgId)),
                  child: Text(l.retry),
                ),
              ],
            ),
          ),
          data: (data) {
            final sessionTemplates = _templatesFor(data, 'session_checklist');
            final milestoneTemplates = _templatesFor(
              data,
              'adoption_milestones',
            );
            final isEmpty =
                sessionTemplates.isEmpty && milestoneTemplates.isEmpty;

            if (isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l.orgDocumentTemplatesEmpty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return ListView(
              key: const Key('org_document_templates_screen'),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.orgDocumentTemplatesIntro,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (sessionTemplates.isNotEmpty) ...[
                  Text(
                    l.orgLegalDocumentsTypeSession,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...sessionTemplates.map(
                    (template) => _TemplateTile(template: template),
                  ),
                  const SizedBox(height: 16),
                ],
                if (milestoneTemplates.isNotEmpty) ...[
                  Text(
                    l.orgLegalDocumentsTypeAdoption,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...milestoneTemplates.map(
                    (template) => _TemplateTile(template: template),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template});

  final Map<String, dynamic> template;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = (template['label'] as String?)?.trim().isNotEmpty == true
        ? template['label'] as String
        : (template['template_key'] as String? ?? '');
    final description = template['description'] as String? ?? '';
    final isPublic = template['is_public'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        title: Text(label),
        subtitle: description.isNotEmpty ? Text(description) : null,
        trailing: isPublic
            ? Icon(Icons.public, color: theme.colorScheme.primary, size: 20)
            : Icon(Icons.lock_outline, color: theme.colorScheme.outline),
      ),
    );
  }
}
