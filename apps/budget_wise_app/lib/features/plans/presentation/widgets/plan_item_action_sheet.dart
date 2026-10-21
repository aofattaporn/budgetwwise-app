import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

import '../../../../domain/entities/plan_item.dart';

/// Bottom sheet menu for plan item actions (Edit / Delete).
class PlanItemActionSheet extends StatelessWidget {
  final PlanItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PlanItemActionSheet({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  /// Shows the bottom sheet and returns the selected action.
  static void show({
    required BuildContext context,
    required PlanItem item,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PlanItemActionSheet(
        item: item,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(context),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Item'),
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: context.colors.expense),
            title: Text('Delete Item',
                style: TextStyle(color: context.colors.expense)),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.colors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
