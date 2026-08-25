import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../di/injection.dart';
import '../../../../domain/entities/plan.dart';
import '../../../../domain/entities/plan_item.dart';
import '../../../../domain/repositories/plan_repository.dart';
import '../widgets/plan_item_card.dart';
import 'plan_editor_page.dart';
import 'plan_item_editor_page.dart';

/// Detail page for a single plan (summary view)
/// Supports viewing plan details, editing, and managing plan items
class PlanDetailPage extends StatefulWidget {
  final Plan plan;

  const PlanDetailPage({
    super.key,
    required this.plan,
  });

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage> {
  final PlanRepository _planRepository = getIt<PlanRepository>();

  // ═══════════════════════════════════════════════════════════════════════════
  // state usage
  // ═══════════════════════════════════════════════════════════════════════════
  late Plan _currentPlan;
  List<PlanItem> _planItems = [];
  bool _isLoading = false;
  bool _isLoadingItems = true;

  /// Calculate total planned expenses from items
  double get _totalPlannedExpenses {
    return _planItems.fold(0.0, (sum, item) => sum + item.expectedAmount);
  }

  /// Calculate total actual expenses from items
  double get _totalActualExpenses {
    return _planItems.fold(0.0, (sum, item) => sum + item.actualAmount);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _currentPlan = widget.plan;
    _loadPlanItems();
  }

  /// Load plan items from repository
  Future<void> _loadPlanItems() async {
    setState(() => _isLoadingItems = true);
    try {
      final items = await _planRepository.getPlanItems(_currentPlan.id);
      if (mounted) {
        setState(() {
          _planItems = items;
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingItems = false);
      }
      debugPrint('Failed to load plan items: $e');
    }
  }

  /// Refresh plan data from repository
  Future<void> _refreshPlanData() async {
    setState(() => _isLoading = true);

    try {
      final updatedPlan = await _planRepository.getPlanById(_currentPlan.id);
      if (updatedPlan != null && mounted) {
        setState(() {
          _currentPlan = updatedPlan;
          _isLoading = false;
        });
        await _loadPlanItems();
      } else {
        // Plan was deleted, go back
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        context.showSnackBar('Failed to refresh: $e', isError: true);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Navigate to edit plan and refresh data when returning
  void _navigateToEditPlan() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => PlanEditorPage(
          existingPlan: _currentPlan,
          currentTotalPlanned: _totalPlannedExpenses,
        ),
        fullscreenDialog: true,
      ),
    );

    // If plan was updated, refresh the data
    if (result == true && mounted) {
      await _refreshPlanData();
    }
  }

  /// Navigate to add a new plan item
  void _navigateToAddItem() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => PlanItemEditorPage(
          plan: _currentPlan,
          currentTotalPlanned: _totalPlannedExpenses,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      // Create new plan item
      try {
        await _planRepository.addPlanItem(
          planId: _currentPlan.id,
          name: result['name'] as String,
          description: result['description'] as String?,
          expectedAmount: result['amount'] as double,
          iconIndex: result['iconIndex'] as int?,
          recurrenceType: result['recurrenceType'] as RecurrenceType? ?? RecurrenceType.daily,
        );
        await _loadPlanItems();
      } catch (e) {
        if (mounted) {
          context.showSnackBar('Failed to create item: $e', isError: true);
        }
      }
    }
  }

  /// Navigate to edit a plan item
  void _navigateToEditItem(PlanItem item) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => PlanItemEditorPage(
          plan: _currentPlan,
          existingItem: item,
          currentTotalPlanned: _totalPlannedExpenses,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      try {
        await _planRepository.updatePlanItem(
          item.copyWith(
            name: result['name'] as String,
            description: result['description'] as String?,
            expectedAmount: result['amount'] as double,
            iconIndex: result['iconIndex'] as int?,
            recurrenceType: result['recurrenceType'] as RecurrenceType?,
          ),
        );
        await _loadPlanItems();
      } catch (e) {
        if (mounted) {
          context.showSnackBar('Failed to update item: $e', isError: true);
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOG METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  /// Show item menu with edit and delete options

  void _showItemMenu(PlanItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            context.styles.sheetHandle(),
            ListTile(
              leading: Icon(Icons.edit, color: context.colors.textPrimary),
              title: Text('Edit Item', style: context.styles.bodyMedium),
              onTap: () {
                Navigator.pop(sheetContext);
                _navigateToEditItem(item);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: context.colors.expense),
              title: Text(
                'Delete Item',
                style: TextStyle(color: context.colors.expense),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteItem(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Confirm and delete a plan item
  void _confirmDeleteItem(PlanItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _planRepository.deletePlanItem(item.id);
                await _loadPlanItems();
              } catch (e) {
                if (mounted) {
                  context.showSnackBar('Failed to delete item: $e', isError: true);
                }
              }
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

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - MAIN
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '฿', decimalDigits: 0);

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: context.styles.appBar(
        title: _currentPlan.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditPlan,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: context.colors.accent,
              ),
            )
          : RefreshIndicator(
              color: context.colors.primary,
              onRefresh: _refreshPlanData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Card
                    _buildSummaryCard(dateFormat, currencyFormat),

                    const SizedBox(height: 24),

                    // Plan Items Section
                    _buildPlanItemsSection(),

                    // Bottom padding
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(DateFormat dateFormat, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: context.styles.card,
      child: Column(
        children: [
          // Status Badge
          if (_currentPlan.isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.colors.incomeLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 18, color: context.colors.income),
                  const SizedBox(width: 8),
                  Text(
                    'Active Plan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.colors.income,
                    ),
                  ),
                ],
              ),
            ),

          // Date Range
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 20,
                color: context.colors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                '${dateFormat.format(_currentPlan.startDate)} - ${dateFormat.format(_currentPlan.endDate)}',
                style: context.styles.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: context.colors.divider),
          const SizedBox(height: 16),

          // Budget Summary
          if (_currentPlan.expectedIncome != null) ...[
            _SummaryRow(
              label: 'Expected Income',
              value: CurrencyUtils.formatCurrency(
                  _currentPlan.expectedIncome ?? 0),
              valueColor: context.colors.accent,
            ),
            const SizedBox(height: 12),
          ],

          _SummaryRow(
            label: 'Total Items Planned',
            value: CurrencyUtils.formatCurrency(_totalPlannedExpenses),
            valueColor: context.colors.textSecondary,
          ),
          const SizedBox(height: 12),

          _SummaryRow(
            label: 'Total Spent',
            value: CurrencyUtils.formatCurrency(_totalActualExpenses),
            valueColor: _totalActualExpenses > _totalPlannedExpenses
                ? context.colors.expense
                : context.colors.textSecondary,
          ),

          if (_currentPlan.expectedIncome != null) ...[
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Remaining Budget',
              value: CurrencyUtils.formatCurrency(
                _currentPlan.expectedIncome! - _totalActualExpenses,
              ),
              valueColor:
                  (_currentPlan.expectedIncome! - _totalActualExpenses) < 0
                      ? context.colors.expense
                      : context.colors.income,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Plan Items', style: context.styles.titleMedium),
            GestureDetector(
              onTap: _navigateToAddItem,
              child: Row(
                children: [
                  Icon(
                    Icons.add,
                    size: 18,
                    color: context.colors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add Item',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Items List
        if (_isLoadingItems)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: context.colors.accent,
              ),
            ),
          )
        else if (_planItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: context.colors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text('No plan items yet', style: context.styles.bodyLarge),
                  const SizedBox(height: 4),
                  Text('Add items to track your budget', style: context.styles.bodySmall),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                    style: context.styles.primaryButton.copyWith(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _planItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _planItems[index];
              return PlanItemCard(
                item: item,
                onTap: () => _navigateToEditItem(item),
                onMenuTap: () => _showItemMenu(item),
              );
            },
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.styles.bodyMedium.copyWith(color: context.colors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
