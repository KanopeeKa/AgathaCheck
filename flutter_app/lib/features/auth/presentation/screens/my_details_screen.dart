import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'export_data_stub.dart' if (dart.library.html) 'export_data_web.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/auth_service.dart';
import '../providers/auth_providers.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/change_password_form.dart';
import '../widgets/account_actions_section.dart';
import '../widgets/my_details/profile_editor_sheet.dart';
import '../widgets/my_details/profile_settings_section.dart';

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
    return resolveStaticAssetUrl(
      photoUrl,
      apiBaseUrl: ref.read(apiBaseUrlProvider),
    );
  }

  void _openEditorSheet() {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ProfileEditorSheet(
        user: user,
        resolvePhotoUrl: _resolvePhotoUrl,
        onSave:
            ({
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
              await ref
                  .read(authProvider.notifier)
                  .updateProfile(
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
      final msg = await ref
          .read(authProvider.notifier)
          .changePassword(
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
                ProfileSettingsSection(
                  theme: theme,
                  l10n: l10n,
                  currentLocale: currentLocale,
                  onSubscription: () => context.push('/subscription'),
                  onOrganizations: () => context.push('/organizations'),
                  onLocaleChanged: (value) {
                    ref.read(localeProvider.notifier).setLocale(Locale(value));
                    ref
                        .read(authProvider.notifier)
                        .updateProfile(locale: value);
                  },
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
                  onToggleObscureCurrent: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  onToggleObscureNew: () =>
                      setState(() => _obscureNew = !_obscureNew),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.dataExported)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$e')));
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
