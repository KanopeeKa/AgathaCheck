import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'export_data_stub.dart'
  if (dart.library.html) 'export_data_web.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/auth_service.dart';
import '../providers/auth_providers.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/change_password_form.dart';
import '../widgets/account_actions_section.dart';

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
    // Resolve relative upload paths against the shared API base URL
    // ('/backend' on web) for consistency with the rest of the app.
    final baseUrl = ref.read(apiBaseUrlProvider);
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
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider)?.languageCode ?? 'en';

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l10n.myDetails)),
        body: Center(child: Text(l10n.notLoggedIn)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: AppLogoTitle(title: l10n.myDetails)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeaderCard(
                  user: user,
                  theme: theme,
                  l10n: l10n,
                  onEdit: _openEditorSheet,
                  resolvePhotoUrl: _resolvePhotoUrl,
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    key: const Key('subscription_tile'),
                    leading: Icon(
                      Icons.workspace_premium,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.subscription),
                    subtitle: Text(l10n.managePlan),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/subscription'),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    key: const Key('organizations_tile'),
                    leading: Icon(
                      Icons.business,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.myOrganizations),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/organizations'),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.language),
                    trailing: DropdownButton<String>(
                      value: currentLocale,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'fr',
                          child: Text('Français'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(localeProvider.notifier).setLocale(Locale(value));
                          ref.read(authProvider.notifier).updateProfile(locale: value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ChangePasswordForm(
                  formKey: _passwordFormKey,
                  currentPasswordController: _currentPasswordController,
                  newPasswordController: _newPasswordController,
                  confirmPasswordController: _confirmPasswordController,
                  obscureCurrent: _obscureCurrent,
                  obscureNew: _obscureNew,
                  changingPassword: _changingPassword,
                  passwordMessage: _passwordMessage,
                  passwordSuccess: _passwordSuccess,
                  onChangePassword: _changePassword,
                  onToggleObscureCurrent: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  onToggleObscureNew: () => setState(() => _obscureNew = !_obscureNew),
                  l10nChangePassword: l10n.changePassword,
                  l10nCurrentPassword: l10n.currentPassword,
                  l10nShowCurrentPassword: l10n.showCurrentPassword,
                  l10nHideCurrentPassword: l10n.hideCurrentPassword,
                  l10nCurrentPasswordRequired: l10n.currentPasswordRequired,
                  l10nNewPassword: l10n.newPassword,
                  l10nShowNewPassword: l10n.showNewPassword,
                  l10nHideNewPassword: l10n.hideNewPassword,
                  l10nNewPasswordRequired: l10n.newPasswordRequired,
                  l10nAtLeast6Characters: l10n.atLeast6Characters,
                  l10nConfirmNewPassword: l10n.confirmNewPassword,
                  l10nPasswordsDoNotMatch: l10n.passwordsDoNotMatch,
                ),
                const SizedBox(height: 16),
                AccountActionsSection(
                  theme: theme,
                  l10nAboutUs: l10n.aboutUs,
                  l10nExportMyData: l10n.exportMyData,
                  l10nExportMyDataSubtitle: l10n.exportMyDataSubtitle,
                  l10nConsentSettings: l10n.consentSettings,
                  l10nConsentManagePreferences: l10n.consentManagePreferences,
                  l10nDeleteAccount: l10n.deleteAccount,
                  l10nDeleteAccountSubtitle: l10n.deleteAccountSubtitle,
                  onAbout: () => context.push('/about'),
                  onExport: () => _exportData(context),
                  onConsent: () => context.push('/consent-settings'),
                  onDelete: () => _showDeleteAccountDialog(context),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final token = ref.read(authProvider).accessToken;
    if (token == null) return;

    try {
      final authService = AuthService();
      final data = await authService.exportData(token);
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = utf8.encode(jsonStr);

      if (kIsWeb) {
        await exportUserDataWebOnly(bytes);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dataExported)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.deleteAccountWarning),
            const SizedBox(height: 16),
            AutofillGroup(
              child: TextField(
              controller: passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: l10n.currentPassword,
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final token = ref.read(authProvider).accessToken;
                if (token == null) return;
                final authService = AuthService();
                await authService.deleteAccount(token, password: password);
                if (mounted) {
                  ref.read(authProvider.notifier).logout();
                  context.go('/landing');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  l10n.failedToSave(e.toString().replaceFirst('Exception: ', '')))),
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
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: l10n.firstName,
                prefixIcon: const Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: l10n.lastName,
                prefixIcon: const Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: l10n.bio,
                prefixIcon: const Icon(Icons.edit_note),
                hintText: 'Tell others about yourself...',
              ),
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
            ),
                ],
              ),
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
                  : Text(l10n.save),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

