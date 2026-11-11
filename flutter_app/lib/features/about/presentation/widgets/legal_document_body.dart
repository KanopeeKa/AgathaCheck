import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

class LegalDocumentBody extends StatelessWidget {
  const LegalDocumentBody({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MarkdownBody(
      data: markdown,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        h1: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        h2: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          height: 2.0,
        ),
        h3: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.8,
        ),
        p: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        listBullet: theme.textTheme.bodyMedium,
        blockquotePadding: const EdgeInsets.symmetric(horizontal: 16),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
      ),
      onTapLink: (text, href, title) {
        unawaited(_handleLinkTap(context, href));
      },
    );
  }

  Future<void> _handleLinkTap(BuildContext context, String? href) async {
    if (href == null || href.isEmpty) return;
    if (href.startsWith('/')) {
      context.push(href);
      return;
    }
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    final l = AppLocalizations.of(context)!;
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showLinkFallback(context, href, l);
      }
    } catch (_) {
      if (context.mounted) {
        _showLinkFallback(context, href, l);
      }
    }
  }

  void _showLinkFallback(BuildContext context, String url, AppLocalizations l) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l.legalInformation),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.externalLinkOpenFailed),
              const SizedBox(height: 12),
              SelectableText(url),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.peopleCopiedToClipboard)),
                  );
                }
              },
              child: Text(l.copy),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.ok),
            ),
          ],
        );
      },
    );
  }
}
