import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/web/native_login.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/auth/presentation/widgets/landing/landing_login_form.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _FakeNativeLogin extends NativeLogin {
  @override
  bool get isAvailable => false;
}

void main() {
  testWidgets('LandingLoginForm shows email field', (tester) async {
    final email = TextEditingController();
    final password = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l = AppLocalizations.of(context)!;
            return Scaffold(
              body: LandingLoginForm(
                theme: Theme.of(context),
                auth: const AuthState(),
                l10n: l,
                formKey: GlobalKey<FormState>(),
                emailController: email,
                passwordController: password,
                onSubmit: () async {},
                onClearError: () {},
                nativeLogin: _FakeNativeLogin(),
                onNativeLogin: (_, __) async {},
                onNativeForgot: () {},
              ),
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
  });
}
