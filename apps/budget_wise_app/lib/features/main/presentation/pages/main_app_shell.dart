import 'package:app_template/features/accounts/domain/entities/account.dart';
import 'package:app_template/features/accounts/domain/repositories/account_repository.dart';
import 'package:app_template/features/accounts/presentation/bloc/account_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/injection.dart';
import '../../../../domain/repositories/plan_repository.dart';
import '../widgets/widgets.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/pages/home_overview_page.dart';
import '../../../plans/presentation/bloc/active_plan_bloc.dart';
import '../../../plans/presentation/pages/active_plan_page.dart';
import '../../../transactions/transactions.dart';
import '../../../accounts/accounts.dart';
import '../../../settings/settings.dart';

/// Main App Shell with Bottom Navigation and FAB
///
/// This is the main scaffold that wraps the entire app's navigation structure.
/// It contains:
/// - Bottom Navigation Bar with 5 tabs
/// - Floating Action Button positioned above the nav bar
/// - Content area that switches based on selected tab
///
/// Easy to extend: replace placeholder pages with actual feature pages
class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0; // Default to Home tab (index 0)
  final ValueNotifier<bool> _processingNotifier = ValueNotifier(false);
  late final HomeBloc _homeBloc;
  late final ActivePlanBloc _activePlanBloc;
  late final AccountBloc _accountBloc;

  @override
  void initState() {
    super.initState();
    _homeBloc = HomeBloc(
      planRepository: getIt<PlanRepository>(),
      accountRepository: getIt<AccountRepository>(),
      transactionRepository: getIt<TransactionRepository>(),
    );
    _activePlanBloc = ActivePlanBloc(
      planRepository: getIt<PlanRepository>(),
      transactionRepository: getIt<TransactionRepository>(),
    );
    _accountBloc = AccountBloc(
      repository: getIt<AccountRepository>(),
      transactionRepository: getIt<TransactionRepository>(),
    );
  }

  @override
  void dispose() {
    _homeBloc.close();
    _activePlanBloc.close();
    _accountBloc.close();
    _processingNotifier.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Auto-refresh the target tab's data
    _refreshTab(index);
  }

  void _refreshTab(int index) {
    switch (index) {
      case 0:
        _homeBloc.add(const RefreshHomeData());
        break;
      case 1:
        _activePlanBloc.add(const RefreshActivePlan());
        break;
      case 3:
        _accountBloc.add(const RefreshAccountsRequested());
        break;
    }
  }

  void _refreshAllBlocs() {
    _homeBloc.add(const RefreshHomeData());
    _activePlanBloc.add(const RefreshActivePlan());
    _accountBloc.add(const RefreshAccountsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeBloc),
        BlocProvider.value(value: _activePlanBloc),
        BlocProvider.value(value: _accountBloc),
      ],
      child: ProcessingOverlay(
        notifier: _processingNotifier,
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              const HomeOverviewPage(),
              const ActivePlanPage(),
              const TransactionsPlaceholderPage(),
              const AccountScreen(),
              const SettingsPlaceholderPage(),
            ],
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        ),
      ),
    );
  }
}

/// Provides a global processing overlay that covers all screens.
/// Child widgets can access via [ProcessingOverlay.of(context)].
class ProcessingOverlay extends InheritedWidget {
  final ValueNotifier<bool> notifier;

  const ProcessingOverlay({
    super.key,
    required this.notifier,
    required super.child,
  });

  static ProcessingOverlay? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ProcessingOverlay>();
  }

  void show() => notifier.value = true;
  void hide() => notifier.value = false;

  @override
  bool updateShouldNotify(ProcessingOverlay oldWidget) =>
      notifier != oldWidget.notifier;

  @override
  ProcessingOverlayElement createElement() => ProcessingOverlayElement(this);
}

class ProcessingOverlayElement extends InheritedElement {
  ProcessingOverlayElement(ProcessingOverlay super.widget);

  @override
  Widget build() {
    final overlay = widget as ProcessingOverlay;
    return ValueListenableBuilder<bool>(
      valueListenable: overlay.notifier,
      builder: (context, isProcessing, _) {
        return Stack(
          children: [
            overlay.child,
            if (isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: Card(
                    elevation: 8,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF4D648D)),
                          SizedBox(height: 16),
                          Text(
                            'Updating data...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
