# Plan Revision (ปรับแผนกลางเดือน + ประวัติเวอร์ชัน)

> Status: **IMPLEMENTED (v1)** — Oct 27, 2026. Migration `add_plan_revisions` is applied to the live DB.

## Problem

Partway through a period, it's clear some categories won't be used up (no
football this month, fuel came in under budget) while others are short.
Today the only fix is editing `expectedAmount` on each item, which overwrites
the original design. Nothing records what the plan first looked like, or how a
category would have ended under the original numbers.

## Goal

- **"ปรับแผน"**: redesign the whole plan at once. The new version becomes the
  current plan and reads cleanly, with no "moved in / moved out" noise.
- **History**: browse earlier versions, see how each one was designed, and see
  how each category would land against it (e.g. "under v1 food is 400 over").

## Current schema (checked live, Oct 27 2026)

| Table | Relevant columns |
|---|---|
| `plans` | `id`, `name`, `start_date`, `end_date`, `expected_income`, `is_active`, `description` |
| `plan_items` | `id`, `plan_id` → plans **ON DELETE CASCADE**, `name`, `expected_amount`, `icon_index`, `recurrence_type`, `is_tracking_only`, `description` |
| `transactions` | `plan_item_id` → plan_items **ON DELETE NO ACTION** |

- The DB already **blocks deleting a plan item that has transactions** (NO ACTION FK).
- RLS on every plan table: one policy, `Authenticated full access`
  (`auth.role() = 'authenticated'`). There are no `user_id` columns, because
  the app is single-user by design.
- Items are edited **one at a time** today (`updatePlanItem` from
  `active_plan_bloc.dart` and `plan_detail_page.dart`). There is no batch edit.

## Design

### Data

`plan_items` always holds the **current** version, so all existing reads,
actuals, and status logic keep working unchanged.

New table: **row N is version N**, a frozen snapshot of that version (the newest
row is the current design). `note` is why that version was made.

```sql
create table public.plan_revisions (
  id              uuid primary key default gen_random_uuid(),
  plan_id         uuid not null references public.plans(id) on delete cascade,
  revision_no     int  not null,          -- 1 = original design
  note            text,                   -- why it was revised
  expected_income numeric,
  items           jsonb not null,         -- [{item_id, name, expected_amount, icon_index, is_tracking_only}]
  created_at      timestamptz not null default now(),
  unique (plan_id, revision_no)
);
alter table public.plan_revisions enable row level security;
create policy "Authenticated full access" on public.plan_revisions
  for all using (auth.role() = 'authenticated');
```

- Snapshot items are keyed by `item_id`, so actuals (already summed per
  `plan_item_id`) map onto any version for free. Nothing extra is stored,
  keeping the **actuals are computed** rule.
- If there are no rows, the plan was never revised.
- Atomic RPC `revise_plan(p_plan_id, p_amounts jsonb, p_note)` (SECURITY INVOKER,
  so RLS applies). Once the plan has transactions, the first call records the
  original design as v1 (dated `plans.created_at`), applies the amounts, then
  records the result as v2, v3, …. With no transactions it only overwrites and
  returns null.

### Flow

1. Tap **"ปรับแผน"** to open a batch editor with every item's amount editable at
   once, a running total checked against `expected_income`, and an optional note.
2. On save, in this order: insert a snapshot of the **current** state into
   `plan_revisions`, then write the new amounts to `plan_items`. This should be
   one atomic step, either an RPC/SQL function or snapshot first with a
   rollback on failure.
3. Adding a new item during a revision is fine. **Removing** an item that has
   transactions is not: set it to 0 instead (the FK enforces this anyway).

### Rules

- Skip creating a revision when the plan hasn't started or has no transactions
  yet. Edits then overwrite in place, so typo fixes don't spawn v1…v10.
- The new version still obeys the budget cap (sum ≤ `expected_income`,
  tracking-only items exempt).
- Status (overBudget / nearLimit ≥ 85% / noActivity / inProgress) always uses
  the **current** amounts.
- **Every amount change is versioned.** `PlanRepositoryImpl.updatePlanItem`
  (single-item edits) also calls `revise_plan`, so history can't drift from the
  live plan. The RPC returns null and records nothing when no amount changes.
- **The budget cap is enforced in the RPC as well**, not only in the UI. The
  call raises if the total exceeds `expected_income`, but only when the total
  grows, so an already-over plan can still be trimmed (migration
  `revise_plan_skip_noop_and_cap`).
- **Restore covers budget amounts only.** Names, tracking flags and items added
  later are kept. Restore is offered on any version whose budgets differ from
  the live plan.

### UI

```
Plan tab header
┌─────────────────────────────────────┐
│ ตุลาคม 2026          v2 · ปรับ 15 ต.ค. ›│
└─────────────────────────────────────┘

ประวัติแผน
  ● v2  15 ต.ค.  "น้ำมันไม่ถึง ย้ายไปอาหาร"   (ปัจจุบัน)
  ○ v1   1 ต.ค.  แผนเริ่มต้น

ดู v1 (read-only)
                งบ v1   ใช้จริง   ผลถ้ายังใช้ v1
⛽ น้ำมัน         3,000    1,200    เหลือ 1,800
🍜 อาหาร         5,000    5,400    เกิน 400  🔴
⚽ บอล           1,000        0    เหลือ 1,000
```
- Optional small hint under a revised item on the current plan, e.g. `v1: 3,000`.

## Open questions

1. ~~**"ใช้จริง" on an old version**~~ **Decided: today's actuals** (v1 ships
   that view only; the as-of-revision figure is not built yet).: today's actuals ("how would it land now")
   or actuals as of the revision date ("what it looked like when I decided")?
   Leaning toward today's actuals as the main number, with the as-of-revision
   figure shown small. The as-of figure is computable from `occurred_at`, so
   nothing extra needs storing.
2. **End-of-period summary** comparing v1 with the final version (e.g. "fuel
   was over-budgeted by 1,800"), to feed next month's plan?

## Implementation notes

- Plans live in the **shared/root layout** (`lib/{data,domain}`), not a
  feature folder. Add the revision datasource/repository methods there (Supabase
  path only, like most features).
- New: `PlanRevision` entity/model, `getPlanRevisions(planId)`,
  `revisePlan(planId, items, note)`.
- Manual DI registration in `lib/di/injection.dart` if a new repository is added.
- Tests: snapshot-then-update ordering, the skip-revision rule, mapping actuals
  onto an old snapshot, the budget cap on a revised version.
