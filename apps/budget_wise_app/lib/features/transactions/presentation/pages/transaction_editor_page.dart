import 'package:app_template/features/plans/plans.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/extensions.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../../domain/entities/plan_item.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transaction_editor_bloc.dart';

class TransactionEditorPage extends StatefulWidget {
  final Transaction? transaction;

  const TransactionEditorPage({super.key, this.transaction});

  @override
  State<TransactionEditorPage> createState() => _TransactionEditorPageState();
}

class _TransactionEditorPageState extends State<TransactionEditorPage> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.transaction?.description ?? '',
    );
    context.read<TransactionEditorBloc>().add(
          TransactionEditorLoaded(transaction: widget.transaction),
        );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - MAIN
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionEditorBloc, TransactionEditorState>(
      listener: _handleStateChanges,
      builder: (context, state) {
        final isLoading = state.status == TransactionEditorStatus.loading ||
            state.status == TransactionEditorStatus.initial;
        final showActions = state.status == TransactionEditorStatus.ready ||
            state.status == TransactionEditorStatus.saving ||
            state.status == TransactionEditorStatus.error;
        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: AppStyles.appBar(
            title: state.isEditing ? 'Edit Transaction' : 'Create Transaction',
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Column(
                  children: [
                    Expanded(child: _buildForm(state)),
                    if (showActions) _buildBottomActions(state),
                  ],
                ),
        );
      },
    );
  }

  void _handleStateChanges(
      BuildContext context, TransactionEditorState state) {
    if (state.status == TransactionEditorStatus.error &&
        state.errorMessage != null) {
      context.showSnackBar(state.errorMessage!, isError: true);
    }
    if (state.status == TransactionEditorStatus.success) {
      context.showSnackBar(
        state.isEditing
            ? 'Transaction updated successfully'
            : 'Transaction created successfully',
      );
      Navigator.pop(context, true);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  // _buildAppBar removed — using AppStyles.appBar() inline above

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - FORM
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildForm(TransactionEditorState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransactionTypeSelector(state),
          const SizedBox(height: 24),
          _buildAmountInput(state),
          const SizedBox(height: 24),
          _buildAccountSelector(state),
          const SizedBox(height: 24),
          if (state.type == TransactionType.transfer) ...[  
            _buildDestinationAccountSelector(state),
            const SizedBox(height: 24),
          ],
          if (state.type == TransactionType.expense ||
              state.type == TransactionType.income) ...[
            _buildPlanItemSelector(state),
            const SizedBox(height: 24),
          ],
          _buildDateTimeSelector(state),
          const SizedBox(height: 24),
          _buildDescriptionInput(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - TRANSACTION TYPE SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTransactionTypeSelector(TransactionEditorState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transaction Type', style: AppStyles.label),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTypeButton(
              state,
              type: TransactionType.expense,
              icon: Icons.remove,
              label: 'Expense',
            ),
            const SizedBox(width: 8),
            _buildTypeButton(
              state,
              type: TransactionType.income,
              icon: Icons.add,
              label: 'Income',
            ),
            const SizedBox(width: 8),
            _buildTypeButton(
              state,
              type: TransactionType.transfer,
              icon: Icons.swap_horiz,
              label: 'Transfer',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton(
    TransactionEditorState state, {
    required TransactionType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = state.type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => context
            .read<TransactionEditorBloc>()
            .add(TransactionTypeChanged(type)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - AMOUNT INPUT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAmountInput(TransactionEditorState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amount', style: AppStyles.label),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('฿', style: TextStyle(fontSize: 24, color: AppColors.textTertiary)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  textAlign: TextAlign.center,
                  style: AppStyles.displayLarge,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(fontSize: 28, color: AppColors.textTertiary),
                  ),
                  onChanged: (value) => context.read<TransactionEditorBloc>().add(TransactionAmountChanged(value)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - ACCOUNT SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAccountSelector(TransactionEditorState state) {
    final label = state.type == TransactionType.income ? 'To Account' : 'From Account';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.label),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showAccountPicker(state),
          child: Container(
            padding: const EdgeInsets.all(AppDimens.cardPadding),
            decoration: AppStyles.card,
            child: Row(
              children: [
                AppStyles.iconBox(icon: Icons.account_balance_wallet, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.selectedAccount?.name ?? 'Select Account',
                        style: state.selectedAccount != null ? AppStyles.bodyLarge : AppStyles.bodySmall,
                      ),
                      if (state.selectedAccount != null)
                        Text(
                          'Balance: ${CurrencyUtils.formatCurrency(state.selectedAccount!.balance)}',
                          style: AppStyles.caption,
                        ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAccountPicker(TransactionEditorState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AccountPickerSheet(
        accounts: state.accounts,
        selectedId: state.selectedAccountId,
        onSelected: (id) {
          context
              .read<TransactionEditorBloc>()
              .add(TransactionAccountChanged(id));
          Navigator.pop(context);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - DESTINATION ACCOUNT SELECTOR (Transfer)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDestinationAccountSelector(TransactionEditorState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('To Account', style: AppStyles.label),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showDestinationAccountPicker(state),
          child: Container(
            padding: const EdgeInsets.all(AppDimens.cardPadding),
            decoration: AppStyles.card,
            child: Row(
              children: [
                AppStyles.iconBox(icon: Icons.account_balance_wallet, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.selectedDestinationAccount?.name ?? 'Select Destination Account',
                        style: state.selectedDestinationAccount != null ? AppStyles.bodyLarge : AppStyles.bodySmall,
                      ),
                      if (state.selectedDestinationAccount != null)
                        Text(
                          'Balance: ${CurrencyUtils.formatCurrency(state.selectedDestinationAccount!.balance)}',
                          style: AppStyles.caption,
                        ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDestinationAccountPicker(TransactionEditorState state) {
    // Exclude the source account from destination options
    final availableAccounts = state.accounts
        .where((a) => a.id != state.selectedAccountId)
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AccountPickerSheet(
        accounts: availableAccounts,
        selectedId: state.selectedDestinationAccountId,
        onSelected: (id) {
          context
              .read<TransactionEditorBloc>()
              .add(TransactionDestinationAccountChanged(id));
          Navigator.pop(context);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - PLAN ITEM SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlanItemSelector(TransactionEditorState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Plan Item (Optional)', style: AppStyles.label),
            Icon(Icons.info_outline, size: 16, color: AppColors.textTertiary),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: state.planItems.isNotEmpty ? () => _showPlanItemPicker(state) : null,
          child: Container(
            padding: const EdgeInsets.all(AppDimens.cardPadding),
            decoration: AppStyles.card,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.selectedPlanItem?.name ?? 'Select Plan Item',
                        style: state.selectedPlanItem != null ? AppStyles.bodyLarge : AppStyles.bodySmall,
                      ),
                      if (state.selectedPlanItem != null)
                        Text(
                          'Remaining: ${CurrencyUtils.formatCurrency(state.selectedPlanItem!.remainingAmount)}',
                          style: AppStyles.caption,
                        ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.type == TransactionType.income
              ? 'Link income to a plan budget item.'
              : 'Plan items help you track spending against your plan.',
          style: AppStyles.caption,
        ),
      ],
    );
  }

  void _showPlanItemPicker(TransactionEditorState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PlanItemPickerSheet(
        planItems: state.planItems,
        selectedId: state.selectedPlanItemId,
        onSelected: (id) {
          context
              .read<TransactionEditorBloc>()
              .add(TransactionPlanItemChanged(id));
          Navigator.pop(context);
        },
        onClear: () {
          context
              .read<TransactionEditorBloc>()
              .add(const TransactionPlanItemChanged(''));
          Navigator.pop(context);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - DATE/TIME SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDateTimeSelector(TransactionEditorState state) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date & Time', style: AppStyles.label),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(state),
                child: Container(
                  padding: const EdgeInsets.all(AppDimens.cardPadding),
                  decoration: AppStyles.card,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date', style: AppStyles.caption),
                            const SizedBox(height: 4),
                            Text(dateFormat.format(state.occurredAt), style: AppStyles.bodyMedium),
                          ],
                        ),
                      ),
                      Icon(Icons.calendar_today, size: 18, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickTime(state),
                child: Container(
                  padding: const EdgeInsets.all(AppDimens.cardPadding),
                  decoration: AppStyles.card,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time', style: AppStyles.caption),
                          const SizedBox(height: 4),
                          Text(timeFormat.format(state.occurredAt), style: AppStyles.bodyMedium),
                        ],
                      ),
                      Icon(Icons.access_time, size: 18, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(TransactionEditorState state) async {
    final date = await showDatePicker(
      context: context,
      initialDate: state.occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      context
          .read<TransactionEditorBloc>()
          .add(TransactionDateChanged(date));
    }
  }

  Future<void> _pickTime(TransactionEditorState state) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(state.occurredAt),
    );
    if (time != null && mounted) {
      context
          .read<TransactionEditorBloc>()
          .add(TransactionTimeChanged(time));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - DESCRIPTION INPUT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description (Optional)', style: AppStyles.label),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          style: AppStyles.bodyMedium,
          decoration: AppStyles.input(hint: 'e.g. Coffee & Breakfast'),
          onChanged: (value) => context.read<TransactionEditorBloc>().add(TransactionDescriptionChanged(value)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - BOTTOM ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomActions(TransactionEditorState state) {
    final isSaving = state.status == TransactionEditorStatus.saving;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                style: AppStyles.secondaryButton,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () => context.read<TransactionEditorBloc>().add(const TransactionEditorSubmitted()),
                style: AppStyles.primaryButton,
                child: isSaving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(state.isEditing ? 'Update' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM SHEETS
// ═══════════════════════════════════════════════════════════════════════════

class _AccountPickerSheet extends StatelessWidget {
  final List<Account> accounts;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const _AccountPickerSheet({
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Select Account', style: AppStyles.titleLarge),
          ),
          const SizedBox(height: 12),
          ...accounts.map((account) => ListTile(
                leading: AppStyles.iconBox(icon: Icons.account_balance_wallet, size: 36),
                title: Text(account.name, style: AppStyles.bodyLarge),
                subtitle: Text(
                  'Balance: ${CurrencyUtils.formatCurrency(account.balance)}',
                  style: AppStyles.caption,
                ),
                trailing: account.id == selectedId
                    ? const Icon(Icons.check_circle, color: AppColors.accent)
                    : null,
                onTap: () => onSelected(account.id),
              )),
        ],
      ),
    );
  }
}

class _PlanItemPickerSheet extends StatelessWidget {
  final List<PlanItem> planItems;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  const _PlanItemPickerSheet({
    required this.planItems,
    required this.selectedId,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Select Plan Item', style: AppStyles.titleLarge),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: AppStyles.iconBox(
                icon: Icons.clear,
                size: 36,
                bgColor: AppColors.surfaceLight,
                iconColor: AppColors.textTertiary,
              ),
              title: Text('None', style: AppStyles.bodyLarge),
              subtitle: Text('No plan item linked', style: AppStyles.caption),
              trailing: selectedId.isEmpty
                  ? const Icon(Icons.check_circle, color: AppColors.accent)
                  : null,
              onTap: onClear,
            ),
            ...planItems.map((item) => ListTile(
                  leading: AppStyles.iconBox(icon: PlanItemIcon.getIcon(item.iconIndex), size: 36),
                  title: Text(item.name, style: AppStyles.bodyLarge),
                  subtitle: Text(
                    'Remaining: ${CurrencyUtils.formatCurrency(item.remainingAmount)}',
                    style: AppStyles.caption,
                  ),
                  trailing: item.id == selectedId
                      ? const Icon(Icons.check_circle, color: AppColors.accent)
                      : null,
                  onTap: () => onSelected(item.id),
                )),
          ],
        ),
      ),
    );
  }
}
