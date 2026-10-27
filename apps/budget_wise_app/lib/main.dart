import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetwise_design_system/budgetwise_design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'core/theme/theme_provider.dart';
import 'di/injection.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  await configureDependencies();
  if (kDebugMode) await _devAutoSignIn();

  runApp(const ProviderScope(child: BudgetWiseApp()));
}

/// Debug-only: signs in with DEV_EMAIL / DEV_PASSWORD from `.env` so local
/// runs skip the login page. Falls back to the login page if unset or failing.
Future<void> _devAutoSignIn() async {
  final email = AppConfig.get('DEV_EMAIL');
  final password = AppConfig.get('DEV_PASSWORD');
  final auth = Supabase.instance.client.auth;
  if (email.isEmpty || password.isEmpty || auth.currentSession != null) return;
  try {
    await auth.signInWithPassword(email: email, password: password);
  } catch (e) {
    debugPrint('Dev auto sign-in failed: $e');
  }
}

class BudgetWiseApp extends ConsumerWidget {
  const BudgetWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'BudgetWise',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,

      // Router
      routerConfig: router,
    );
  }
}
