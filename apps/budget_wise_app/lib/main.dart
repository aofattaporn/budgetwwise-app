import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetwise_design_system/budgetwise_design_system.dart';

import 'config/app_config.dart';
import 'core/theme/theme_provider.dart';
import 'di/injection.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  await configureDependencies();
  
  runApp(const ProviderScope(child: BudgetWiseApp()));
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

