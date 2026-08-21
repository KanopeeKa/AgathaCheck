import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../../../../core/web/native_login.dart';
import '../widgets/landing/landing_auth_forms.dart';
import '../widgets/landing/landing_operations_desk_page.dart';

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
    _nativeLogin.detach();
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
      context.go('/app/resolve');
    }
  }

  Future<void> _handleNativeLogin(String email, String password) async {
    ref.read(authProvider.notifier).clearError();

    await ref
        .read(authProvider.notifier)
        .login(email: email.trim(), password: password);

    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isLoggedIn) {
      TextInput.finishAutofillContext();
      _nativeLogin.detach();
      context.go('/app/resolve');
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
      context.go('/app/resolve');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
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
        onNativeLogin: _handleNativeLogin,
        onNativeForgot: () {
          if (mounted) context.go('/forgot-password');
        },
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

    return LandingOperationsDeskPage(
      baseTheme: theme,
      l10n: l10n,
      authCard: authCard,
    );
  }
}
