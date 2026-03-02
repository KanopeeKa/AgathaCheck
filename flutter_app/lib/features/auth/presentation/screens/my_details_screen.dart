import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/auth_providers.dart';

class MyDetailsScreen extends ConsumerStatefulWidget {
  const MyDetailsScreen({super.key});

  @override
  ConsumerState<MyDetailsScreen> createState() => _MyDetailsScreenState();
}

class _MyDetailsScreenState extends ConsumerState<MyDetailsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _changingPassword = false;
  String? _passwordMessage;
  bool _passwordSuccess = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _resolvePhotoUrl(String photoUrl) {
    if (photoUrl.isEmpty) return '';
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return photoUrl;
    }
    final baseUrl = kIsWeb ? '' : 'http://localhost:5000';
    return '$baseUrl$photoUrl';
  }

  void _openEditorSheet() {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ProfileEditorSheet(
        user: user,
        resolvePhotoUrl: _resolvePhotoUrl,
        onSave: ({
          required String firstName,
          required String lastName,
          required String category,
          required String bio,
          Uint8List? photoBytes,
          String? photoFilename,
        }) async {
          if (photoBytes != null && photoFilename != null) {
            await ref
                .read(authProvider.notifier)
                .uploadPhoto(photoBytes, photoFilename);
          }
          await ref.read(authProvider.notifier).updateProfile(
                firstName: firstName,
                lastName: lastName,
                category: category,
                bio: bio,
              );
        },
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() {
      _changingPassword = true;
      _passwordMessage = null;
    });

    try {
      final msg = await ref.read(authProvider.notifier).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (mounted) {
        setState(() {
          _changingPassword = false;
          _passwordMessage = msg;
          _passwordSuccess = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _changingPassword = false;
          _passwordMessage = e.toString().replaceFirst('Exception: ', '');
          _passwordSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Details')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MergeSemantics(
                  child: Semantics(
                    label: '${user.displayName}, ${user.email}, ${user.category == 'professional_multi_pet' ? 'Professional Multi Pet' : 'Pet Guardian'}',
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 48,
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    backgroundImage: user.photoUrl.isNotEmpty
                                        ? NetworkImage(
                                            _resolvePhotoUrl(user.photoUrl))
                                        : null,
                                    child: user.photoUrl.isNotEmpty
                                        ? null
                                        : Text(
                                            user.initials,
                                            style: theme.textTheme.headlineMedium
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    user.displayName,
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Semantics(
                                    label: user.category == 'professional_multi_pet'
                                        ? 'Category: Professional Multi Pet'
                                        : 'Category: Pet Guardian',
                                    child: _CategoryBadge(category: user.category),
                                  ),
                                  if (user.bio.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      user.bio,
                                      style: theme.textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondaryContainer.withAlpha(120),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.info_outline,
                                            size: 16,
                                            color: theme.colorScheme.onSecondaryContainer),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'These details are visible to people you share pets with',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                tooltip: 'Edit profile',
                                icon: const Icon(Icons.edit),
                                onPressed: _openEditorSheet,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                MergeSemantics(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _passwordFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Change Password',
                                style: theme.textTheme.titleLarge),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _currentPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  tooltip: _obscureCurrent
                                      ? 'Show current password'
                                      : 'Hide current password',
                                  icon: Icon(_obscureCurrent
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(
                                      () => _obscureCurrent = !_obscureCurrent),
                                ),
                              ),
                              obscureText: _obscureCurrent,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Current password is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _newPasswordController,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                prefixIcon: const Icon(Icons.lock_reset),
                                suffixIcon: IconButton(
                                  tooltip: _obscureNew
                                      ? 'Show new password'
                                      : 'Hide new password',
                                  icon: Icon(_obscureNew
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(
                                      () => _obscureNew = !_obscureNew),
                                ),
                              ),
                              obscureText: _obscureNew,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'New password is required';
                                }
                                if (v.length < 6) {
                                  return 'At least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: const InputDecoration(
                                labelText: 'Confirm New Password',
                                prefixIcon: Icon(Icons.lock_reset),
                              ),
                              obscureText: true,
                              validator: (v) {
                                if (v != _newPasswordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            if (_passwordMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _passwordSuccess
                                      ? Colors.green.shade50
                                      : theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _passwordSuccess
                                          ? Icons.check_circle
                                          : Icons.error_outline,
                                      color: _passwordSuccess
                                          ? Colors.green
                                          : theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(_passwordMessage!,
                                            style: TextStyle(
                                                color: _passwordSuccess
                                                    ? Colors.green.shade800
                                                    : theme.colorScheme.error))),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                key: const Key('change_password_button'),
                                onPressed:
                                    _changingPassword ? null : _changePassword,
                                child: _changingPassword
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Text('Change Password'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final isPro = category == 'professional_multi_pet';
    return Chip(
      avatar: Icon(
        isPro ? Icons.business_center : Icons.pets,
        size: 18,
        color: isPro ? Colors.teal : Colors.deepPurple,
      ),
      label: Text(
        isPro ? 'Professional Multi Pet' : 'Pet Guardian',
        style: TextStyle(
          color: isPro ? Colors.teal : Colors.deepPurple,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isPro
          ? Colors.teal.withAlpha(25)
          : Colors.deepPurple.withAlpha(25),
      side: BorderSide.none,
    );
  }
}

class _ProfileEditorSheet extends StatefulWidget {
  const _ProfileEditorSheet({
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
  }) onSave;

  @override
  State<_ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<_ProfileEditorSheet> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  late String _category;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoFilename;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.user.firstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.user.lastName ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _category = widget.user.category ?? 'pet_guardian';
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to save: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              'Edit Profile',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: Semantics(
                label: 'Profile photo. Tap to change',
                button: true,
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: _selectedPhotoBytes != null
                            ? MemoryImage(_selectedPhotoBytes!)
                            : (photoUrl.isNotEmpty
                                ? NetworkImage(
                                        widget.resolvePhotoUrl(photoUrl))
                                    as ImageProvider
                                : null),
                        child: (_selectedPhotoBytes == null &&
                                photoUrl.isEmpty)
                            ? Text(
                                initials,
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt,
                              size: 16, color: theme.colorScheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'pet_guardian',
                  label: Text('Pet Guardian'),
                  icon: Icon(Icons.pets),
                ),
                ButtonSegment(
                  value: 'professional_multi_pet',
                  label: Text('Professional'),
                  icon: Icon(Icons.business_center),
                ),
              ],
              selected: {_category},
              onSelectionChanged: (val) {
                setState(() => _category = val.first);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                prefixIcon: Icon(Icons.edit_note),
                hintText: 'Tell others about yourself...',
              ),
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('save_profile_button'),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
