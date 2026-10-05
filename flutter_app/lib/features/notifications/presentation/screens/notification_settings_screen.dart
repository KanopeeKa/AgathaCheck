import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/entities/notification_settings_matrix.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_settings_care_reminders_section.dart';
import '../widgets/notification_settings_matrix_section.dart';
import '../widgets/notification_settings_muted_pets_section.dart';
import '../widgets/notification_settings_push_hint.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _emailReminders = false;
  int _reminderDays = 1;
  bool _notifyOverdue = true;
  bool _notifyDueSoon = true;
  bool _notifyCompleted = true;
  List<String> _mutedPetIds = [];
  bool _agathaInApp = true;
  NotificationSettingsMatrix _matrix = NotificationSettingsMatrix.defaults();
  Map<String, bool> _suggestionTypes = defaultSuggestionTypeToggles();
  bool _initialized = false;
  bool _saving = false;

  final _careRemindersKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    final l = AppLocalizations.of(context)!;
    final pushDenied = NotificationSettingsPushHint.osPushDenied();

    prefsAsync.whenData((prefs) {
      if (!_initialized) {
        _emailReminders = prefs.emailRemindersEnabled;
        _reminderDays = prefs.reminderDaysBefore;
        _notifyOverdue = prefs.notifyOverdue;
        _notifyDueSoon = prefs.notifyDueSoon;
        _notifyCompleted = prefs.notifyCompleted;
        _mutedPetIds = List<String>.from(prefs.mutedPetIds);
        _agathaInApp = prefs.agathaSuggestionsInApp;
        _matrix = prefs.settingsMatrix;
        _suggestionTypes = Map<String, bool>.from(prefs.suggestionTypes);
        _initialized = true;
      }
    });

    final pets = ref.watch(petListProvider).valueOrNull ?? [];
    final petMuteRows = pets
        .map(
          (pet) => NotificationSettingsPetMuteRow(
            id: pet.id,
            name: pet.name,
            accentColor: resolvePetAccentColor(context, pet),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: l.notificationSettings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l.notificationSettingsTooltip,
          onPressed: () => context.pop(),
        ),
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (_) => ListView(
          children: [
            const SizedBox(height: 8),
            NotificationSettingsPushHint(showHint: pushDenied),
            NotificationSettingsMatrixSection(
              matrix: _matrix,
              suggestionTypes: _suggestionTypes,
              agathaSuggestionsInApp: _agathaInApp,
              pushOsDenied: pushDenied,
              onMatrixChanged: (m) => setState(() => _matrix = m),
              onSuggestionTypesChanged: (t) =>
                  setState(() => _suggestionTypes = t),
              onAgathaInAppChanged: (v) => setState(() => _agathaInApp = v),
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: Text(l.notificationSettingsCareRemindersLink),
              subtitle: Text(l.notificationSettingsCareRemindersLinkHelp),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Scrollable.ensureVisible(
                  _careRemindersKey.currentContext!,
                  duration: const Duration(milliseconds: 300),
                );
              },
            ),
            const Divider(),
            KeyedSubtree(
              key: _careRemindersKey,
              child: NotificationSettingsCareRemindersSection(
                emailReminders: _emailReminders,
                reminderDays: _reminderDays,
                notifyOverdue: _notifyOverdue,
                notifyDueSoon: _notifyDueSoon,
                notifyCompleted: _notifyCompleted,
                onEmailRemindersChanged: (v) =>
                    setState(() => _emailReminders = v),
                onReminderDaysChanged: (v) => setState(() => _reminderDays = v),
                onNotifyOverdueChanged: (v) =>
                    setState(() => _notifyOverdue = v),
                onNotifyDueSoonChanged: (v) =>
                    setState(() => _notifyDueSoon = v),
                onNotifyCompletedChanged: (v) =>
                    setState(() => _notifyCompleted = v),
              ),
            ),
            const Divider(),
            NotificationSettingsMutedPetsSection(
              pets: petMuteRows,
              mutedPetIds: _mutedPetIds,
              onMutedChanged: (ids) => setState(() => _mutedPetIds = ids),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                key: const Key('save_notification_settings_button'),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(l.saveSettings),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(notificationPreferencesProvider.notifier)
          .updatePreferences(
            NotificationPreferences(
              emailRemindersEnabled: _emailReminders,
              reminderDaysBefore: _reminderDays,
              notifyOverdue: _notifyOverdue,
              notifyDueSoon: _notifyDueSoon,
              notifyCompleted: _notifyCompleted,
              mutedPetIds: _mutedPetIds,
              agathaSuggestionsInApp: _agathaInApp,
              settingsMatrix: _matrix,
              suggestionTypes: _suggestionTypes,
            ),
          );
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.settingsSaved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
