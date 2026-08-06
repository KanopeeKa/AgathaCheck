import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/org_permissions_providers.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

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

    return OrgShellScaffold(
      title: l.orgCustomisationsTemplatesTitle,
      orgId: orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: const Key('org_document_templates_back'),
      child: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final sessionTemplates = _templatesFor(data, 'session_checklist');
          final milestoneTemplates = _templatesFor(data, 'adoption_milestones');
          final emailTemplates = _templatesFor(data, 'email_templates');
          final isEmpty = sessionTemplates.isEmpty &&
              milestoneTemplates.isEmpty &&
              emailTemplates.isEmpty;

          if (isEmpty) {
            return Center(child: Text(l.orgDocumentTemplatesEmpty));
          }

          return ListView(
            key: const Key('org_document_templates_screen'),
            padding: const EdgeInsets.all(16),
            children: [
              Text(l.orgDocumentTemplatesIntro,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (emailTemplates.isNotEmpty) ...[
                Text(l.orgEmailTemplatesSection,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...emailTemplates.map(
                  (t) => _EmailTemplateTile(orgId: orgId, template: t),
                ),
                const SizedBox(height: 16),
              ],
              if (sessionTemplates.isNotEmpty) ...[
                Text(l.orgLegalDocumentsTypeSession,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...sessionTemplates.map((t) => _TemplateTile(template: t)),
                const SizedBox(height: 16),
              ],
              if (milestoneTemplates.isNotEmpty) ...[
                Text(l.orgLegalDocumentsTypeAdoption,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...milestoneTemplates.map((t) => _TemplateTile(template: t)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EmailTemplateTile extends ConsumerWidget {
  const _EmailTemplateTile({required this.orgId, required this.template});

  final String orgId;
  final Map<String, dynamic> template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final templateKey = template['template_key']?.toString() ?? '';
    final locale = template['locale']?.toString() ?? 'en';
    final subject = template['subject']?.toString() ?? '';

    return Card(
      child: ListTile(
        title: Text('$templateKey ($locale)'),
        subtitle: subject.isNotEmpty ? Text(subject) : null,
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => _edit(context, ref, templateKey, locale, template, l),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    String templateKey,
    String locale,
    Map<String, dynamic> template,
    AppLocalizations l,
  ) async {
    final subjectController = TextEditingController(
      text: template['subject']?.toString() ?? '',
    );
    final bodyController = TextEditingController(
      text: template['body_text']?.toString() ?? '',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l.orgEmailTemplateEditorTitle}: $templateKey'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.orgEmailTemplateEditorHint, style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 8),
            TextField(
              controller: subjectController,
              decoration: InputDecoration(labelText: l.orgEmailTemplateSubject),
            ),
            TextField(
              controller: bodyController,
              decoration: InputDecoration(labelText: l.orgEmailTemplateBody),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
        ],
      ),
    );
    if (saved != true) {
      subjectController.dispose();
      bodyController.dispose();
      return;
    }
    try {
      await ref.read(documentTemplatesProvider(orgId).notifier).updateEmailTemplate(
        templateKey,
        subject: subjectController.text.trim(),
        bodyHtml: '<p>${bodyController.text.trim()}</p>',
        bodyText: bodyController.text.trim(),
        locale: locale,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.orgEmailTemplateSaved)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    subjectController.dispose();
    bodyController.dispose();
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template});
  final Map<String, dynamic> template;

  @override
  Widget build(BuildContext context) {
    final label = (template['label'] as String?)?.trim().isNotEmpty == true
        ? template['label'] as String
        : (template['template_key'] as String? ?? '');
    return Card(
      child: ListTile(title: Text(label)),
    );
  }
}
