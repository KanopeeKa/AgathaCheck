import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'features/pet_profile/presentation/providers/pet_providers.dart';

/// Entry point for the PetProfileApp.
///
/// Initializes SharedPreferences and sets up the Riverpod
/// provider scope before launching the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PetProfileApp(),
    ),
  );
}

/// The root widget for the PetProfileApp.
///
/// Configures Material 3 theming and GoRouter navigation.
class PetProfileApp extends StatelessWidget {
  /// Creates the [PetProfileApp].
  const PetProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appTitle,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
