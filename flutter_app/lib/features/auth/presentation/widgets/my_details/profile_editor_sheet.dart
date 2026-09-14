import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/widgets/form/app_form_actions_bar.dart';
import '../../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../../l10n/app_localizations.dart';
import '../profile_photo_avatar.dart';

/// Bottom-sheet editor for the current user's profile (name, bio, category and
/// photo). Extracted from `MyDetailsScreen` to keep the screen slim.
class ProfileEditorSheet extends StatefulWidget {
  const ProfileEditorSheet({
    super.key,
    required this.user,
    required this.resolvePhotoUrl,
    required this.onSave,
  });

  final dynamic user;
  final String Function(String) resolvePhotoUrl;
  final Future<void> Function({
    required String firstName,
    required String lastName,
    required String category,
    required String bio,
    Uint8List? photoBytes,
    String? photoFilename,
  })
  onSave;

  @override
  State<ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<ProfileEditorSheet> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  late String _category;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoFilename;
  bool _isSaving = false;
  late Map<String, String> _baseline;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.user.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.user.lastName ?? '',
    );
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _category = widget.user.category ?? 'pet_carer';
    _baseline = _snapshot();
    for (final controller in [
      _firstNameController,
      _lastNameController,
      _bioController,
    ]) {
      controller.addListener(() => setState(() {}));
    }
  }

  Map<String, String> _snapshot() => {
    'firstName': _firstNameController.text,
    'lastName': _lastNameController.text,
    'bio': _bioController.text,
    'category': _category,
    'photo': _selectedPhotoFilename ?? '',
  };

  bool get _isDirty => _snapshot().toString() != _baseline.toString();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedPhotoBytes = bytes;
        _selectedPhotoFilename = picked.name;
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToPickPhoto(e.toString()))),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        category: _category,
        bio: _bioController.text.trim(),
        photoBytes: _selectedPhotoBytes,
        photoFilename: _selectedPhotoFilename,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.failedToSave(e.toString().replaceFirst('Exception: ', '')),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final photoUrl = widget.user.photoUrl ?? '';
    final initials = widget.user.initials ?? '';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(102),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Text(
              l10n.editProfile,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: Semantics(
                label: 'Profile photo. Tap to change',
                button: true,
                child: ProfilePhotoAvatar(
                  photoUrl: photoUrl.isNotEmpty
                      ? widget.resolvePhotoUrl(photoUrl)
                      : null,
                  initials: initials,
                  photoBytes: _selectedPhotoBytes,
                  onTap: _pickPhoto,
                  showEditIcon: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFormLabeledField(
                    label: l10n.firstName,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(),
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.givenName],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppFormLabeledField(
                    label: l10n.lastName,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(),
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.familyName],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppFormLabeledField(
                    label: l10n.bio,
                    child: TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        hintText: 'Tell others about yourself...',
                      ),
                      maxLines: 3,
                      maxLength: 200,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppFormActionsBar(
              isLoading: _isSaving,
              isDirty: _isDirty,
              onSave: _save,
              onCancel: () => Navigator.of(context).pop(),
              saveLabel: l10n.save,
              cancelKey: const Key('cancel_profile_button'),
              saveKey: const Key('save_profile_button'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
