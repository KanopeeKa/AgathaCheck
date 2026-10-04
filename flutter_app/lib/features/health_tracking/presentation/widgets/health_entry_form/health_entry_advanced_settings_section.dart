import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../care_taxonomy/domain/care_importance.dart';
import '../../../../care_taxonomy/domain/care_setting.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/datasources/health_remote_datasource.dart';
import '../../../domain/entities/health_entry.dart';
import '../../../domain/entities/recurrence_anchor.dart';
import '../../controllers/health_entry_form_controller.dart';
import '../care_provider_field.dart';
import '../late_completion_choice_field.dart';
import 'care_setting_importance_fields.dart';
import 'health_entry_advanced_settings_summary.dart';
import 'health_entry_photos_section.dart';
import 'schedule_type_field.dart';

/// Collapsed Advanced settings (D-CIE-027, UIR-13).
class HealthEntryAdvancedSettingsSection extends StatefulWidget {
  const HealthEntryAdvancedSettingsSection({
    super.key,
    required this.careSetting,
    required this.careImportance,
    required this.frequency,
    required this.recurrenceAnchor,
    required this.lateCompletionChoice,
    required this.providerContactId,
    required this.providerTypedName,
    required this.photos,
    required this.pendingPhotos,
    required this.isUploadingPhoto,
    required this.baseUrl,
    required this.controller,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onDeletePhoto,
    required this.onRemovePendingPhoto,
    this.initiallyExpanded = false,
  });

  final CareSetting careSetting;
  final CareImportance careImportance;
  final HealthFrequency frequency;
  final RecurrenceAnchor recurrenceAnchor;
  final String? lateCompletionChoice;
  final String? providerContactId;
  final String? providerTypedName;
  final List<EventPhoto> photos;
  final List<XFile> pendingPhotos;
  final bool isUploadingPhoto;
  final String baseUrl;
  final HealthEntryFormController controller;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final ValueChanged<EventPhoto> onDeletePhoto;
  final void Function(int index) onRemovePendingPhoto;
  final bool initiallyExpanded;

  @override
  State<HealthEntryAdvancedSettingsSection> createState() =>
      _HealthEntryAdvancedSettingsSectionState();
}

class _HealthEntryAdvancedSettingsSectionState
    extends State<HealthEntryAdvancedSettingsSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final summary = healthEntryAdvancedSettingsSummary(
      l,
      careSetting: widget.careSetting,
      careImportance: widget.careImportance,
      frequency: widget.frequency,
      recurrenceAnchor: widget.recurrenceAnchor,
      lateCompletionChoice: widget.lateCompletionChoice,
    );

    return Semantics(
      label: '${l.healthEntryFormAdvancedSettings}. $summary',
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        child: ExpansionTile(
          key: const Key('health_entry_advanced_settings'),
          initiallyExpanded: _expanded,
          onExpansionChanged: (open) => setState(() => _expanded = open),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          minTileHeight: 48,
          title: Text(
            l.healthEntryFormAdvancedSettings,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(summary, style: theme.textTheme.bodySmall),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CareSettingImportanceFields(
                    careSetting: widget.careSetting,
                    careImportance: widget.careImportance,
                    onCareSettingChanged: widget.controller.setCareSetting,
                    onCareImportanceChanged:
                        widget.controller.setCareImportance,
                  ),
                  if (widget.frequency != HealthFrequency.once) ...[
                    const SizedBox(height: 16),
                    ScheduleTypeField(
                      value: widget.recurrenceAnchor,
                      onChanged: widget.controller.setRecurrenceAnchor,
                    ),
                    const SizedBox(height: 16),
                    LateCompletionChoiceField(
                      value: widget.lateCompletionChoice,
                      allowShift:
                          widget.recurrenceAnchor ==
                          RecurrenceAnchor.fromDueDate,
                      onChanged: widget.controller.setLateCompletionChoice,
                    ),
                  ],
                  const SizedBox(height: 16),
                  CareProviderField(
                    contactId: widget.providerContactId,
                    typedName: widget.providerTypedName,
                    onChanged: widget.controller.setProvider,
                  ),
                  const SizedBox(height: 16),
                  HealthEntryPhotosSection(
                    photos: widget.photos,
                    pendingPhotos: widget.pendingPhotos,
                    isUploading: widget.isUploadingPhoto,
                    baseUrl: widget.baseUrl,
                    onPickCamera: widget.onPickCamera,
                    onPickGallery: widget.onPickGallery,
                    onDelete: widget.onDeletePhoto,
                    onRemovePending: widget.onRemovePendingPhoto,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
