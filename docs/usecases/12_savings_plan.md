# Savings Plan (เงินออมสะสมข้ามเดือน)

> Status: **DESIGN / NOT STARTED** — Drafted: October 21, 2026

## Problem

A PlanItem lives inside one Plan only. If the user budgets "ออมเงิน 3,000" every
month and doesn't spend it, the app can't tell them how much savings has piled
up across months.

Gaps in the current code:

- An untouched savings item has no transactions, so it reads as `noActivity`.
  For savings that means "goal met", but the app can't tell the two apart.
- Each month's savings item is a separate row, so nothing links "ออมเงิน" in
  one month to "ออมเงิน" in another.
- `getPlanItemActuals` (`plan_supabase_datasource.dart`) counts only `expense`
  and `income`. **Transfers never count**, even when tagged to a plan item.

## Goal

Show how much of an account's balance is accumulated savings, e.g.

```
KBank เงินเดือน   50,000 ฿
  เงินออม  9,000  (3 เดือน × 3,000)
  ใช้ได้   41,000
```

## Concept

1. **Savings-type PlanItem**: a third item type next to spending and
   tracking-only.
2. **Savings Pot**: a long-lived entity, independent of any plan, linked to an
   account (optional target amount). Each month's savings PlanItem links to the
   same pot.
3. **Pot balance = contributions − withdrawals**, computed at read time and
   never stored, which keeps the "actuals are computed" rule.

## Two modes

| | A. Keep in the same account (the user's real case) | B. Transfer to a separate account |
|---|---|---|
| What counts as saved | Counted at plan end (planned amount, editable), or a "ยืนยันออม" button | A `transfer` tagged to the savings item |
| Accuracy | Assumed: unspent money is treated as savings | Real money movement |
| Monthly effort | None | One transfer (pre-filled) |
| Effort to build | More (virtual pot) | Less (reuses transfers) |

Both modes use the same pot and the same balance formula, so they can be built
together. **Mode A is the primary target**, because the user keeps savings in
their salary account.

## Spending savings

Savings must be spendable, but spending them is kept separate from the
current month's budget.

| Scenario | Behaviour |
|---|---|
| Withdraw 10,000 from savings to fix a car | Pot −10,000, **does not hit this month's budget** |
| Overspent this month, want to cover it from savings | The user chooses "ใช้เงินออม" explicitly. The app never deducts from the pot on its own |

Recording: in the transaction editor, choose "จ่ายจากเงินออม" (pick a pot)
instead of a plan item.

## UI

### 1. Plan item editor
```
ประเภท   ( ) ใช้จ่าย   (•) ออมเงิน   ( ) ติดตามอย่างเดียว
ยอดต่อเดือน   3,000
กระเป๋าออม    [ 🐷 เงินฉุกเฉิน ▾ ]
โอนไปบัญชี    [ 🏦 KBank ออมทรัพย์ ▾ ]   (optional, mode B)
```

### 2. Plan tab card: progress is inverted (100% is good)
```
┌──────────────────────────────────┐
│ 🐷 ออมเงิน                ⏳ ยังไม่ออม │
│ 0 / 3,000         ░░░░░░░░░░     │
│               [ โอนเข้าบัญชีออม → ] │   ← mode B only
└──────────────────────────────────┘
┌──────────────────────────────────┐
│ 🐷 ออมเงิน                ✅ ออมครบ  │
│ 3,000 / 3,000     ██████████     │
│ สะสมทั้งหมด 9,000                 │
└──────────────────────────────────┘
```
- Green progress, never "over budget" or "near limit" (same as `isTrackingOnly`).
- Mode B: the button opens a transfer form pre-filled with the source and
  destination accounts, the remaining amount, and the tagged item.
- Near month end with nothing saved: Home shows a reminder card.

### 3. Transaction editor
- A transfer whose destination is a pot-linked account gets the savings item
  tagged automatically.
- An expense can be marked "จ่ายจากเงินออม".

### 4. Account tab
```
Mode A                                 Mode B
┌──────────────────────────┐   ┌──────────────────────────┐
│ 🏦 KBank เงินเดือน  50,000 │   │ 🏦 KBank ออม      52,000 │
│  ├ เงินออม       9,000   │   │  ├ จากแผนออม     9,000   │
│  └ ใช้ได้        41,000   │   │  └ เงินเดิม/อื่นๆ  43,000   │
│  [ ใช้เงินออม ]            │   │  [ ถอนเงินออม ]            │
└──────────────────────────┘   └──────────────────────────┘
```

## Open questions

1. **When does a month count as saved?** (a) the full planned amount
   automatically at plan end, editable (recommended); (b) the user confirms each
   month; (c) only if the real balance covers it.
2. **Overspending other categories**: should it reduce the pot, or leave the pot
   alone and let "ใช้ได้" go negative? (Leaning: leave the pot alone.)
3. **Multiple pots** (เงินฉุกเฉิน, ทริปญี่ปุ่น) with their own targets, or one is enough?
4. **Pot currency**: follows the linked account. The JPY→THB conversion is needed
   for the totals.

## Implementation notes (to confirm against the live schema)

- New table `savings_pots` (id, name, account_id, target_amount, created_at),
  plus `plan_items.item_type` (or `savings_pot_id`), plus a way to tag
  transactions to a pot. **Introspect Supabase first.**
- Feature-first layout: `lib/features/savings/`.
- Savings items are excluded from the "total planned spending" aggregates
  (Home, Active Plan, Insight), the same way tracking-only items are.
- Creating a new plan should carry savings items and their pot link forward.
- Tests: pot balance calculation, savings item status, mode B transfers
  counting toward the savings item.
