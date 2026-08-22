import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/vet_providers.dart';
import '../utils/vet_accent.dart';

/// Display-first vet detail screen (D24). Edit is a separate route.
///
/// Call and Email are presented as primary action buttons so they are
/// immediately discoverable, not hidden inside a detail row.  When a phone
/// number or email address is absent the corresponding action is omitted so
/// the screen never implies that an unavailable contact method can be used.
/// When the device launcher reports that it cannot open the URI the screen
/// reports the failure via a SnackBar rather than silently doing nothing.
class VetDetailScreen extends ConsumerWidget {
  const VetDetailScreen({
    super.key,
    required this.vetId,
    this.listPath = '/g/vets',
  });

  final String vetId;
  final String listPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final vetListAsync = ref.watch(vetListProvider);
    final pets = ref.watch(petListProvider).valueOrNull ?? [];

    return vetListAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l.failedToLoadVets('$e'))),
      data: (vets) {
        final vet = vets.where((v) => v.id == vetId).firstOrNull;
        if (vet == null) {
          return Center(child: Text(l.vetNotFound));
        }

        final linkedPets = pets.where((p) => p.vetId == vet.id).toList();
        final accent = resolveVetAccent(
          context,
          organizationId: vet.organizationId,
        );

        final hasPhone = vet.phone.isNotEmpty;
        final hasEmail = vet.email.isNotEmpty;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Identity card ───────────────────────────────────────────
              Card(
                color: accent.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: accent.primary.withAlpha(60),
                            child: Icon(
                              Icons.local_hospital,
                              color: accent.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              vet.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (vet.address.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _DetailRow(
                          icon: Icons.location_on_outlined,
                          label: l.address,
                          value: vet.address,
                        ),
                      ],
                      if (hasPhone) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.phone_outlined,
                          label: l.phone,
                          value: vet.phone,
                        ),
                      ],
                      if (hasEmail) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.email_outlined,
                          label: l.vetEmail,
                          value: vet.email,
                        ),
                      ],
                      if (vet.website.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.language,
                          label: l.website,
                          value: vet.website,
                        ),
                      ],
                      if (vet.notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.notes,
                          label: l.vetNotes,
                          value: vet.notes,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Primary contact actions ─────────────────────────────────
              const SizedBox(height: 12),
              _VetContactActions(
                phone: vet.phone,
                email: vet.email,
                hasPhone: hasPhone,
                hasEmail: hasEmail,
              ),

              // ── Linked pets ─────────────────────────────────────────────
              if (linkedPets.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l.vetLinkedPets,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...linkedPets.map(
                  (pet) => ListTile(
                    leading: const Icon(Icons.pets),
                    title: Text(pet.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/pet/${pet.id}'),
                  ),
                ),
              ],

              // ── Edit ────────────────────────────────────────────────────
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('vet_detail_edit_button'),
                onPressed: () => context.go('$listPath/edit/$vetId'),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l.editVet),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Contact action buttons
// ---------------------------------------------------------------------------

/// Renders prominently-sized Call and Email buttons for whichever contact
/// methods the vet record actually provides.
///
/// Each button occupies at least 48 dp in height and uses an icon + label so
/// the action is readable at a glance and discoverable by screen-readers.
/// When both phone and email are absent the widget collapses to nothing rather
/// than presenting an empty row — the absence is already clear from the detail
/// card above which shows no phone or email field.
///
/// If the device launcher reports that it cannot open the URI (e.g. no phone
/// or mail app is installed) the widget reports the failure via a [SnackBar]
/// rather than silently doing nothing.
class _VetContactActions extends StatelessWidget {
  const _VetContactActions({
    required this.phone,
    required this.email,
    required this.hasPhone,
    required this.hasEmail,
  });

  final String phone;
  final String email;
  final bool hasPhone;
  final bool hasEmail;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    // Nothing to show when neither contact method is present.
    if (!hasPhone && !hasEmail) return const SizedBox.shrink();

    return Row(
      children: [
        if (hasPhone) ...[
          Expanded(
            child: _ContactButton(
              key: const Key('vet_call_button'),
              icon: Icons.call,
              label: l.adminContactsCall,
              tooltip: '${l.adminContactsCall} ${l.phone}',
              onPressed: () => _launchTel(context, phone, l),
            ),
          ),
        ],
        if (hasPhone && hasEmail) const SizedBox(width: 12),
        if (hasEmail) ...[
          Expanded(
            child: _ContactButton(
              key: const Key('vet_email_button'),
              icon: Icons.mail_outline,
              label: l.vetEmail,
              tooltip: l.vetEmail,
              onPressed: () => _launchMail(context, email, l),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _launchTel(
    BuildContext context,
    String phone,
    AppLocalizations l,
  ) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await _launch(context, uri, l);
  }

  Future<void> _launchMail(
    BuildContext context,
    String email,
    AppLocalizations l,
  ) async {
    final uri = Uri(scheme: 'mailto', path: email);
    await _launch(context, uri, l);
  }

  Future<void> _launch(
    BuildContext context,
    Uri uri,
    AppLocalizations l,
  ) async {
    bool canLaunch = false;
    try {
      canLaunch = await canLaunchUrl(uri);
    } catch (_) {
      canLaunch = false;
    }

    if (!canLaunch) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_launchFailedMessage(uri.scheme, l))),
        );
      }
      return;
    }

    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_launchFailedMessage(uri.scheme, l))),
        );
      }
    }
  }

  /// Compose a truthful failure message from existing localisation keys.
  ///
  /// There is no dedicated "cannot open phone/email app" ARB entry so the
  /// message uses the action label and retry hint — both localised — to
  /// communicate that something went wrong without silently ignoring it.
  String _launchFailedMessage(String scheme, AppLocalizations l) {
    // e.g. "Call · Retry" / "E-mail · Réessayer"
    final action = scheme == 'tel' ? l.adminContactsCall : l.vetEmail;
    return '$action · ${l.retry}';
  }
}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail row (unchanged visual contract)
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
