import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaari/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:vaari/features/navigation/main_navigation_view.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
// ignore: unused_import
//import 'features/home/presentation/screens/home_screen.dart';
// ignore: unused_import
import 'features/onboarding/view/onboarding_view.dart' show OnboardingView;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authViewModelProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: authState.when(
        data: (user) =>
            user == null ? const OnboardingView() : const MainNavigationView(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => const OnboardingView(),
      ),
    );
  }
}
