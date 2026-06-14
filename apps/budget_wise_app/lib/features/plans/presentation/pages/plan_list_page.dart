import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../di/injection.dart';
import '../../../../domain/entities/plan.dart';
import '../bloc/plan_list_bloc.dart';
import 'plan_detail_page.dart';
import 'plan_editor_page.dart';

/// Page to display list of all plans
class PlanListPage extends StatelessWidget {
  const PlanListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlanListBloc(
        planRepository: getIt(),
      )..add(const LoadAllPlans()),
      child: const _PlanListView(),
    );
  }
}

class _PlanListView extends StatelessWidget {
  const _PlanListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: context.styles.appBar(title: 'All Plans'),
      body: BlocBuilder<PlanListBloc, PlanListState>(
        builder: (context, state) {
          if (state.status == PlanListStatus.loading) {
            return Center(child: CircularProgressIndicator(color: context.colors.primary));
          }

          if (state.status == PlanListStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: context.colors.textTertiary),
                  const SizedBox(height: 16),
                  Text('Failed to load plans', style: context.styles.bodyLarge),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.read<PlanListBloc>().add(const LoadAllPlans()),
                    child: Text('Retry', style: TextStyle(color: context.colors.accent)),
                  ),
                ],
              ),
            );
          }

          if (state.plans.isEmpty) return _buildEmptyState(context);

          return RefreshIndicator(
            color: context.colors.primary,
            onRefresh: () async {
              context.read<PlanListBloc>().add(const RefreshPlans());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.plans.length,
              itemBuilder: (context, index) {
                final plan = state.plans[index];
                return _PlanCard(
                  plan: plan,
                  onTap: () => _viewPlanDetails(context, plan),
                  onSetActive: plan.isActive ? null : () => _confirmSetActive(context, plan),
                  onDelete: () => _confirmDelete(context, plan),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: context.colors.accentLight, shape: BoxShape.circle),
            child: Icon(Icons.calendar_month_rounded, size: 44, color: context.colors.accent),
          ),
          const SizedBox(height: 24),
          Text('No Plans Yet', style: context.styles.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Create your first budget plan\nto start tracking expenses',
            textAlign: TextAlign.center,
            style: context.styles.bodySmall.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreatePlan(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Plan'),
            style: context.styles.primaryButton.copyWith(
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreatePlan(BuildContext context) {
    final bloc = context.read<PlanListBloc>();
    Navigator.of(context)
        .push<dynamic>(
      MaterialPageRoute(
        builder: (_) => const PlanEditorPage(
          currentTotalPlanned: 0,
        ),
        fullscreenDialog: true,
      ),
    )
        .then((result) {
      // Result is true when plan was created successfully via repository
      if (result == true) {
        bloc.add(const RefreshPlans());
      }
    });
  }

  void _viewPlanDetails(BuildContext context, Plan plan) {
    final bloc = context.read<PlanListBloc>();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => PlanDetailPage(plan: plan),
      ),
    )
        .then((_) {
      bloc.add(const RefreshPlans());
    });
  }

  void _confirmSetActive(BuildContext context, Plan plan) {
    final bloc = context.read<PlanListBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set as Active'),
        content: Text(
          'Set "${plan.name}" as your active plan?\n\nThis will deactivate the current active plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(SetActivePlanRequested(planId: plan.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Set Active'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Plan plan) {
    final bloc = context.read<PlanListBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
          'Are you sure you want to delete "${plan.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(DeletePlanRequested(planId: plan.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Card widget to display a single plan
class _PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap;
  final VoidCallback? onSetActive;
  final VoidCallback onDelete;

  const _PlanCard({
    required this.plan,
    required this.onTap,
    required this.onSetActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final isExpired = plan.endDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.cardPadding),
          decoration: context.styles.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(plan.name, style: context.styles.titleLarge)),
                  _buildStatusBadge(context, isExpired),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: context.colors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    '${dateFormat.format(plan.startDate)} - ${dateFormat.format(plan.endDate)}',
                    style: context.styles.bodySmall,
                  ),
                ],
              ),
              if (plan.expectedIncome != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  _InfoChip(
                    label: 'Expected Income',
                    value: CurrencyUtils.formatCurrency(plan.expectedIncome!),
                    color: context.colors.accent,
                  ),
                ]),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onSetActive != null)
                    TextButton.icon(
                      onPressed: onSetActive,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Set Active'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: context.colors.expense,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete plan',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, bool isExpired) {
    if (plan.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: context.colors.incomeLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.income)),
      );
    }

    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: context.colors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Expired', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.textTertiary)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.accentLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('Upcoming', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.accent)),
    );
  }
}

/// Small info chip for displaying budget values
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.accentLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: context.styles.caption),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
