import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../domain/entities/plan.dart';
import '../../../../domain/entities/plan_item.dart';
import '../bloc/active_plan_bloc.dart';
import '../widgets/no_plan_widget.dart';
import '../widgets/plan_item_card.dart';
import '../widgets/plan_overview_section.dart';
import 'plan_editor_page.dart';
import 'plan_item_detail_page.dart';
import 'plan_item_editor_page.dart';
import 'plan_list_page.dart';

/// Active Plan Page - Main screen for viewing and managing the active budget plan
///
/// This page displays:
/// - Plan overview with income/expense summary
/// - List of plan items with their budgets
/// - Options to add/edit/delete items
class ActivePlanPage extends StatefulWidget {
  const ActivePlanPage({super.key});

  @override
  State<ActivePlanPage> createState() => _ActivePlanPageState();
}

class _ActivePlanPageState extends State<ActivePlanPage> {
  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadActivePlan();
  }

  void _loadActivePlan() {
    context.read<ActivePlanBloc>().add(const LoadActivePlan());
  }

  void _refreshActivePlan() {
    context.read<ActivePlanBloc>().add(const RefreshActivePlan());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _navigateToCreatePlan() async {
    final state = context.read<ActivePlanBloc>().state;
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PlanEditorPage(
          currentTotalPlanned: state.totalPlannedExpenses,
        ),
      ),
    );

    if (result == true && mounted) {
      _refreshActivePlan();
    }
  }

  Future<void> _navigateToEditPlan(Plan plan) async {
    final state = context.read<ActivePlanBloc>().state;
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (context) => PlanEditorPage(
          existingPlan: plan,
          currentTotalPlanned: state.totalPlannedExpenses,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true && mounted) {
      _refreshActivePlan();
    }
  }

  void _navigateToAllPlans() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const PlanListPage()))
        .then((_) {
      if (mounted) {
        _refreshActivePlan();
      }
    });
  }

  Future<void> _navigateToAddItem(Plan plan) async {
    final state = context.read<ActivePlanBloc>().state;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => PlanItemEditorPage(
          plan: plan,
          currentTotalPlanned: state.totalPlannedExpenses,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      context.read<ActivePlanBloc>().add(
            AddPlanItemRequested(
              name: result['name'] as String,
              description: result['description'] as String?,
              expectedAmount: result['amount'] as double,
            ),
          );
    }
  }

  Future<void> _navigateToEditItem(Plan plan, PlanItem item) async {
    final state = context.read<ActivePlanBloc>().state;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => PlanItemEditorPage(
          plan: plan,
          existingItem: item,
          currentTotalPlanned: state.totalPlannedExpenses,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      context.read<ActivePlanBloc>().add(
            UpdatePlanItemRequested(
              itemId: item.id,
              name: result['name'] as String,
              description: result['description'] as String?,
              expectedAmount: result['amount'] as double,
            ),
          );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOG METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _navigateToItemDetail(PlanItem item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ActivePlanBloc>(),
          child: PlanItemDetailPage(item: item),
        ),
      ),
    );

    if (mounted) {
      _refreshActivePlan();
    }
  }

  Future<void> _confirmDeleteItem(PlanItem item) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Item',
      message: 'Are you sure you want to delete "${item.name}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      context.read<ActivePlanBloc>().add(DeletePlanItemRequested(item.id));
    }
  }

  Future<void> _confirmClosePlan() async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Close Plan',
      message: 'Are you sure you want to close this plan? '
          'This will make it inactive and you can create a new plan.',
      confirmLabel: 'Close Plan',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      context.read<ActivePlanBloc>().add(const CloseActivePlanRequested());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - MAIN
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: BlocConsumer<ActivePlanBloc, ActivePlanState>(
          listener: _handleStateChanges,
          builder: _buildBody,
        ),
      ),
    );
  }

  void _handleStateChanges(BuildContext context, ActivePlanState state) {
    // error state - show snackbar with error message
    if (state.status == ActivePlanStatus.error && state.errorMessage != null) {
      _showErrorSnackBar(state.errorMessage!);
    }
  }

  Widget _buildBody(BuildContext context, ActivePlanState state) {

    // Loading state - show spinner
    if (state.status == ActivePlanStatus.loading) {
      return _buildLoadingState();
    }

    // No active plan - show empty state with options to create or view plans
    if (!state.hasActivePlan) {
      return _buildNoPlanState();
    }

    // Active plan exists - show plan overview and items
    return _buildActivePlanContent(state);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - STATES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildNoPlanState() {
    return NoPlanWidget(
      onCreatePlan: _navigateToCreatePlan,
      onViewAllPlans: _navigateToAllPlans,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - (existing items) ACTIVE PLAN CONTENT ****
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActivePlanContent(ActivePlanState state) {
    return RefreshIndicator(
      onRefresh: () async => _refreshActivePlan(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanOverview(state),
            _buildPlanItemsSection(state),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanOverview(ActivePlanState state) {
    return PlanOverviewSection(
      plan: state.plan!,
      actualIncome: state.actualIncome,
      totalPlanned: state.totalPlannedExpenses,
      totalSpent: state.totalActualExpenses,
      onEditPlan: () => _navigateToEditPlan(state.plan!),
      onClosePlan: _confirmClosePlan,
      onViewAllPlans: _navigateToAllPlans,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - PLAN ITEMS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlanItemsSection(ActivePlanState state) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 16),
          _buildPlanItemsList(state),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Budget Items', style: AppStyles.titleMedium),
        TextButton.icon(
          onPressed: () {
            final state = context.read<ActivePlanBloc>().state;
            if (state.plan != null) {
              _navigateToAddItem(state.plan!);
            }
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add'),
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
        ),
      ],
    );
  }

  Widget _buildPlanItemsList(ActivePlanState state) {
    final items = state.planItems;

    if (items.isEmpty) {
      return _buildEmptyItemsState();
    }

    return Column(
      children: items.map((item) => _buildPlanItemCard(state, item)).toList(),
    );
  }

  Widget _buildEmptyItemsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppStyles.card,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 36, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('No budget items yet', style: AppStyles.bodyLarge),
            const SizedBox(height: 8),
            Text('Add items to organize your budget', style: AppStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanItemCard(ActivePlanState state, PlanItem item) {
    final plan = state.plan!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PlanItemCard(
        item: item,
        onTap: () => _navigateToItemDetail(item),
        onMenuTap: () => _navigateToItemDetail(item),
      ),
    );
  }
}
