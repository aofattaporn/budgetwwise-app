import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../di/injection.dart';
import '../../../../domain/entities/plan.dart';
import '../../../../domain/entities/plan_item.dart';
import '../../../../domain/entities/plan_revision.dart';
import '../../../../domain/repositories/plan_repository.dart';
import 'plan_item_editor_page.dart';

/// Plan History Page - every recorded version of a plan's design, newest first.
/// Pops `true` when an older version was restored.
class PlanRevisionHistoryPage extends StatefulWidget {
  final Plan plan;

  const PlanRevisionHistoryPage({super.key, required this.plan});

  @override
  State<PlanRevisionHistoryPage> createState() =>
      _PlanRevisionHistoryPageState();
}

class _PlanRevisionHistoryPageState extends State<PlanRevisionHistoryPage> {
  late final Future<(List<PlanRevision>, List<PlanItem>)> _data = _load();

  Future<(List<PlanRevision>, List<PlanItem>)> _load() async {
    final repo = getIt<PlanRepository>();
    final revisions = await repo.getPlanRevisions(widget.plan.id);
    final items = await repo.getPlanItems(widget.plan.id);
    final newestFirst = [...revisions]
      ..sort((a, b) => b.revisionNo.compareTo(a.revisionNo));
    return (newestFirst, items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: context.styles.appBar(title: 'Plan History'),
      body: FutureBuilder<(List<PlanRevision>, List<PlanItem>)>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load history: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            );
          }
          final (revisions, items) = snapshot.data!;
          if (revisions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No revisions yet. Use "Revise" on the plan to re-budget '
                  'mid-period; earlier designs will show up here.',
                  style: context.styles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final (i, rev) in revisions.indexed)
                _buildRevisionTile(rev, items, isCurrent: i == 0),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRevisionTile(
    PlanRevision rev,
    List<PlanItem> items, {
    required bool isCurrent,
  }) {
    final overCount = rev.compareWith(items).where((r) => r.isOver).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: context.styles.card,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isCurrent ? context.colors.accent : context.colors.surfaceLight,
          foregroundColor:
              isCurrent ? context.colors.textOnPrimary : context.colors.textPrimary,
          child: Text('v${rev.revisionNo}'),
        ),
        title: Text(
          rev.note ?? (rev.revisionNo == 1 ? 'Original plan' : 'Revision'),
          style: context.styles.bodyLarge,
        ),
        subtitle: Text(
          '${DateFormat('d MMM yyyy, HH:mm').format(rev.createdAt)}'
          ' · ${CurrencyUtils.formatCurrency(rev.totalPlanned)}'
          '${isCurrent ? ' · current' : ''}'
          '${overCount > 0 ? ' · $overCount over' : ''}',
          style: context.styles.caption,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final restored = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => PlanRevisionDetailPage(
                plan: widget.plan,
                revision: rev,
                items: items,
              ),
            ),
          );
          if (restored == true && mounted) Navigator.of(context).pop(true);
        },
      ),
    );
  }
}

/// One version: its budgets against today's actuals, with an option to
/// restore it. Restoring records a new version, so history is never lost.
/// Pops `true` after a restore.
class PlanRevisionDetailPage extends StatefulWidget {
  final Plan plan;
  final PlanRevision revision;
  final List<PlanItem> items;

  const PlanRevisionDetailPage({
    super.key,
    required this.plan,
    required this.revision,
    required this.items,
  });

  @override
  State<PlanRevisionDetailPage> createState() => _PlanRevisionDetailPageState();
}

class _PlanRevisionDetailPageState extends State<PlanRevisionDetailPage> {
  bool _restoring = false;

  PlanRevision get revision => widget.revision;

  Future<void> _restore() async {
    final amounts = revision.restoreAmounts(widget.items);
    final income = widget.plan.expectedIncome;
    if (income != null && revision.restoredTotal(widget.items) > income) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
            'Restoring would exceed expected income — adjust items added since then first'),
        backgroundColor: context.colors.expense,
      ));
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Restore v${revision.revisionNo}?',
      message: 'Budget amounts go back to this version (${amounts.length} '
          'item(s) change). Names, tracking settings and items added since '
          'are kept. Your current design stays in the history.',
      confirmLabel: 'Restore',
    );
    if (!confirmed || !mounted) return;

    setState(() => _restoring = true);
    try {
      final newRev = await getIt<PlanRepository>().revisePlan(
        revision.planId,
        amounts,
        note: 'Restored v${revision.revisionNo}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Restored v${revision.revisionNo}'
            '${newRev != null ? ' as v$newRev' : ''}'),
      ));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _restoring = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to restore: $e'),
        backgroundColor: context.colors.expense,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = revision.compareWith(widget.items);
    // Offered whenever live budgets differ from this version — not only for
    // older versions — so drift from edits made outside history can be undone.
    final canRestore = revision.restoreAmounts(widget.items).isNotEmpty;
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: context.styles.appBar(
        title: 'Version ${revision.revisionNo}',
        actions: [
          if (canRestore)
            TextButton.icon(
              onPressed: _restoring ? null : _restore,
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Restore'),
              style: TextButton.styleFrom(
                  foregroundColor: context.colors.accent),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (revision.note != null) ...[
            Text('"${revision.note}"', style: context.styles.bodyMedium),
            const SizedBox(height: 4),
          ],
          Text(
            'If you had kept this design, here is how each category would '
            'land with today\'s spending.',
            style: context.styles.caption,
          ),
          const SizedBox(height: 16),
          ...rows.map((r) => _buildRow(context, r)),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, RevisionComparison row) {
    final diff = row.difference;
    final (String label, Color color) = switch (diff) {
      null => ('Not in v${revision.revisionNo}', context.colors.textTertiary),
      _ when row.isTrackingOnly => ('Tracking', context.colors.textSecondary),
      double d when d < 0 => (
          'Over ${CurrencyUtils.formatCurrency(-d)}',
          context.colors.expense
        ),
      double d => ('Left ${CurrencyUtils.formatCurrency(d)}', context.colors.income),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: context.styles.card,
      child: Row(
        children: [
          context.styles.iconBox(icon: PlanItemIcon.getIcon(row.iconIndex)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name, style: context.styles.bodyLarge),
                Text(
                  '${row.budget == null ? '—' : CurrencyUtils.formatCurrency(row.budget!)}'
                  ' budget · ${CurrencyUtils.formatCurrency(row.actual)} spent',
                  style: context.styles.caption,
                ),
              ],
            ),
          ),
          Text(
            label,
            style: context.styles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
