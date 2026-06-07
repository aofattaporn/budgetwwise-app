import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Item'),
              onTap: () {
                Navigator.pop(sheetContext);
                _navigateToEditItem(item);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade700),
              title: Text(
                'Delete Item',
                style: TextStyle(color: Colors.red.shade700),
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
              backgroundColor: Colors.red.shade700,
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
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4D648D),
        foregroundColor: Colors.white,
        title: Text(
          _currentPlan.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditPlan,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4D648D),
              ),
            )
          : RefreshIndicator(
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Badge
          if (_currentPlan.isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 18, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Active Plan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),

          // Date Range
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 20,
                color: Color(0xFF4D648D),
              ),
              const SizedBox(width: 8),
              Text(
                '${dateFormat.format(_currentPlan.startDate)} - ${dateFormat.format(_currentPlan.endDate)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Budget Summary
          if (_currentPlan.expectedIncome != null) ...[
            _SummaryRow(
              label: 'Expected Income',
              value: CurrencyUtils.formatCurrency(
                  _currentPlan.expectedIncome ?? 0),
              valueColor: const Color(0xFF4D648D),
            ),
            const SizedBox(height: 12),
          ],

          _SummaryRow(
            label: 'Total Items Planned',
            value: CurrencyUtils.formatCurrency(_totalPlannedExpenses),
            valueColor: Colors.grey[700]!,
          ),
          const SizedBox(height: 12),

          _SummaryRow(
            label: 'Total Spent',
            value: CurrencyUtils.formatCurrency(_totalActualExpenses),
            valueColor: _totalActualExpenses > _totalPlannedExpenses
                ? Colors.red.shade700
                : Colors.grey[700]!,
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
                      ? Colors.red.shade700
                      : Colors.green.shade700,
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
            const Text(
              'Plan Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: _navigateToAddItem,
              child: const Row(
                children: [
                  Icon(
                    Icons.add,
                    size: 18,
                    color: Color(0xFF4D648D),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Add Item',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4D648D),
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
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: Color(0xFF4D648D),
              ),
            ),
          )
        else if (_planItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No plan items yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add items to track your budget',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4D648D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
          ),
        ),
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
