import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../about/presentation/widgets/legal_footer_links.dart';
import '../providers/auth_providers.dart';
import '../../../../core/web/native_login.dart';
import '../widgets/landing/landing_audience_section.dart';
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
  final _scrollController = ScrollController();
  final _petParentsSectionKey = GlobalKey();
  final _charitiesSectionKey = GlobalKey();

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
    _scrollController.dispose();
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

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
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
    final xp = theme.extension<ExperienceColors>() ?? ExperienceColors.light;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 920;
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

    final hero = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LandingBrandingSection(
                  theme: theme,
                  l10n: l10n,
                  onPetParentsPressed: () =>
                      _scrollToSection(_petParentsSectionKey),
                  onCharitiesPressed: () =>
                      _scrollToSection(_charitiesSectionKey),
                ),
              ),
              const SizedBox(width: 48),
              SizedBox(width: 400, child: authCard),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LandingBrandingSection(
                theme: theme,
                l10n: l10n,
                onPetParentsPressed: () =>
                    _scrollToSection(_petParentsSectionKey),
                onCharitiesPressed: () =>
                    _scrollToSection(_charitiesSectionKey),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: authCard,
                ),
              ),
            ],
          );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 600 ? 20 : 24,
                vertical: screenWidth < 600 ? 24 : 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        hero,
                        const SizedBox(height: 40),
                        KeyedSubtree(
                          key: _petParentsSectionKey,
                          child: LandingAudienceSection(
                            title: l10n.landingPetParentsSectionTitle,
                            body: l10n.landingPetParentsSectionBody,
                            placeholderLabel: l10n.landingScreenshotPlaceholder,
                            accentColor: xp.guardianPrimary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        KeyedSubtree(
                          key: _charitiesSectionKey,
                          child: LandingAudienceSection(
                            title: l10n.landingCharitiesSectionTitle,
                            body: l10n.landingCharitiesSectionBody,
                            placeholderLabel: l10n.landingScreenshotPlaceholder,
                            accentColor: xp.organizationPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const LegalFooterLinks(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
