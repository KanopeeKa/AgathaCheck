import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../../../../core/widgets/web_image.dart';

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
  bool _loginObscure = true;

  final _signupFormKey = GlobalKey<FormState>();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmController = TextEditingController();
  bool _signupObscure = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();

    await ref.read(authProvider.notifier).login(
          email: _loginEmailController.text.trim(),
          password: _loginPasswordController.text,
        );

    if (mounted && ref.read(authProvider).isLoggedIn) {
      context.go('/');
    }
  }

  Future<void> _submitSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();

    await ref.read(authProvider.notifier).signup(
          email: _signupEmailController.text.trim(),
          password: _signupPasswordController.text,
          name: _signupNameController.text.trim(),
        );

    if (mounted && ref.read(authProvider).isLoggedIn) {
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildBrandingSection(theme, l10n)),
                        const SizedBox(width: 48),
                        SizedBox(
                          width: 400,
                          child: _buildAuthCard(theme, auth, l10n),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildBrandingSection(theme, l10n),
                        const SizedBox(height: 32),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: _buildAuthCard(theme, auth, l10n),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme, {required double size}) {
    final fallback = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(Icons.pets, size: size * 0.55, color: theme.colorScheme.primary),
      ),
    );

    return Semantics(
      label: 'Agatha Check logo',
      child: kIsWeb
          ? WebAssetImage(
              assetPath: 'assets/logo.jpg',
              height: size,
              width: size,
              fit: BoxFit.cover,
              fallback: fallback,
              clipOval: true,
            )
          : ClipOval(
              child: Image.asset(
                'assets/logo.jpg',
                height: size,
                width: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
            ),
    );
  }

  Widget _buildBrandingSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogo(theme, size: 120),
        const SizedBox(height: 20),
        Text(
          l10n.appTitle,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Semantics(
          label: 'App tagline',
          child: Text(
            l10n.appTagline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.appDescription,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.appCta,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthCard(ThemeData theme, AuthState auth, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildLogo(theme, size: 64),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.signIn),
                Tab(text: l10n.createAccount),
              ],
              onTap: (_) {
                ref.read(authProvider.notifier).clearError();
              },
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 0) {
                  return _buildLoginForm(theme, auth, l10n);
                } else {
                  return _buildSignupForm(theme, auth, l10n);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme, AuthState auth, AppLocalizations l10n) {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key('login_email_field'),
            controller: _loginEmailController,
            decoration: InputDecoration(
              labelText: l10n.email,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.emailRequired;
              if (!v.contains('@')) return l10n.enterValidEmail;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('login_password_field'),
            controller: _loginPasswordController,
            decoration: InputDecoration(
              labelText: l10n.password,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                tooltip: _loginObscure ? l10n.showPassword : l10n.hidePassword,
                icon: Icon(
                    _loginObscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _loginObscure = !_loginObscure),
              ),
            ),
            obscureText: _loginObscure,
            autofillHints: const [AutofillHints.password],
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.passwordRequired;
              return null;
            },
            onFieldSubmitted: (_) => _submitLogin(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('forgot_password_link'),
              onPressed: () => context.go('/forgot-password'),
              child: Text(
                l10n.forgotPassword,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          _buildErrorBanner(theme, auth),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('login_submit_button'),
              onPressed: auth.isLoading ? null : _submitLogin,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.signIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm(ThemeData theme, AuthState auth, AppLocalizations l10n) {
    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key('signup_name_field'),
            controller: _signupNameController,
            decoration: InputDecoration(
              labelText: l10n.name,
              prefixIcon: const Icon(Icons.person_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('signup_email_field'),
            controller: _signupEmailController,
            decoration: InputDecoration(
              labelText: l10n.email,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.emailRequired;
              if (!v.contains('@')) return l10n.enterValidEmail;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('signup_password_field'),
            controller: _signupPasswordController,
            decoration: InputDecoration(
              labelText: l10n.password,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                tooltip: _signupObscure ? l10n.showPassword : l10n.hidePassword,
                icon: Icon(
                    _signupObscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _signupObscure = !_signupObscure),
              ),
            ),
            obscureText: _signupObscure,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.passwordRequired;
              if (v.length < 6) return l10n.atLeast6Characters;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('signup_confirm_password_field'),
            controller: _signupConfirmController,
            decoration: InputDecoration(
              labelText: l10n.confirmPassword,
              prefixIcon: const Icon(Icons.lock_outlined),
            ),
            obscureText: true,
            validator: (v) {
              if (v != _signupPasswordController.text) {
                return l10n.passwordsDoNotMatch;
              }
              return null;
            },
            onFieldSubmitted: (_) => _submitSignup(),
          ),
          _buildErrorBanner(theme, auth),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('signup_submit_button'),
              onPressed: auth.isLoading ? null : _submitSignup,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.createAccount),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, AuthState auth) {
    if (auth.error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: MergeSemantics(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(Icons.error_outline,
                    color: theme.colorScheme.error, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(auth.error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
