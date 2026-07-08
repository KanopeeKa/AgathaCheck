import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../about/presentation/widgets/legal_footer_links.dart';
import '../providers/auth_providers.dart';
import '../../../../core/web/native_login.dart';
import '../widgets/landing/landing_auth_forms.dart';
import '../widgets/landing/landing_branding_section.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _signupFormKey = GlobalKey<FormState>();
  final _signupFirstNameController = TextEditingController();
  final _signupLastNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmController = TextEditingController();

  final NativeLogin _nativeLogin = createNativeLogin();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nativeLogin.hide();
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupFirstNameController.dispose();
    _signupLastNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();

    await ref
        .read(authProvider.notifier)
        .login(
          email: _loginEmailController.text.trim(),
          password: _loginPasswordController.text,
        );

    if (mounted && ref.read(authProvider).isLoggedIn) {
      TextInput.finishAutofillContext();
      context.go('/');
    }
  }

  void _showNativeLogin() {
    final l10n = AppLocalizations.of(context)!;
    ref.read(authProvider.notifier).clearError();
    _nativeLogin.show(
      email: _loginEmailController.text.trim(),
      title: l10n.signIn,
      subtitle: l10n.signInToAccount,
      emailLabel: l10n.email,
      passwordLabel: l10n.password,
      signInLabel: l10n.signIn,
      forgotLabel: l10n.forgotPassword,
      dismissLabel: l10n.cancel,
      onSubmit: _handleNativeLogin,
      onForgot: () {
        _nativeLogin.hide();
        if (mounted) context.go('/forgot-password');
      },
      onDismiss: _nativeLogin.hide,
    );
  }

  Future<void> _handleNativeLogin(String email, String password) async {
    _loginEmailController.text = email;
    _loginPasswordController.text = password;
    ref.read(authProvider.notifier).clearError();

    await ref
        .read(authProvider.notifier)
        .login(email: email.trim(), password: password);

    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isLoggedIn) {
      TextInput.finishAutofillContext();
      _nativeLogin.hide();
      context.go('/');
    } else {
      _nativeLogin.setBusy(false);
      _nativeLogin.setError(auth.error ?? AppLocalizations.of(context)!.error);
    }
  }

  Future<void> _submitSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();

    await ref
        .read(authProvider.notifier)
        .signup(
          email: _signupEmailController.text.trim(),
          password: _signupPasswordController.text,
          firstName: _signupFirstNameController.text.trim(),
          lastName: _signupLastNameController.text.trim(),
        );

    if (mounted && ref.read(authProvider).isLoggedIn) {
      TextInput.finishAutofillContext();
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;
    final l10n = AppLocalizations.of(context)!;

    final authCard = LandingAuthCard(
      theme: theme,
      auth: auth,
      l10n: l10n,
      tabController: _tabController,
      onTabTap: () => ref.read(authProvider.notifier).clearError(),
      loginForm: LandingLoginForm(
        theme: theme,
        auth: auth,
        l10n: l10n,
        formKey: _loginFormKey,
        emailController: _loginEmailController,
        passwordController: _loginPasswordController,
        onSubmit: _submitLogin,
        onClearError: () => ref.read(authProvider.notifier).clearError(),
        nativeLogin: _nativeLogin,
        onShowNativeLogin: _showNativeLogin,
      ),
      signupForm: LandingSignupForm(
        theme: theme,
        auth: auth,
        l10n: l10n,
        formKey: _signupFormKey,
        firstNameController: _signupFirstNameController,
        lastNameController: _signupLastNameController,
        emailController: _signupEmailController,
        passwordController: _signupPasswordController,
        confirmController: _signupConfirmController,
        onSubmit: _submitSignup,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: LandingBrandingSection(
                                theme: theme,
                                l10n: l10n,
                              ),
                            ),
                            const SizedBox(width: 48),
                            SizedBox(width: 400, child: authCard),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            LandingBrandingSection(theme: theme, l10n: l10n),
                            const SizedBox(height: 32),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: authCard,
                            ),
                          ],
                        ),
                  const SizedBox(height: 24),
                  const LegalFooterLinks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
