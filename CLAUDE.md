# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This is a monorepo. Nearly all work happens in `apps/budget_wise_app` — **run all Flutter/Dart commands from that directory**, not the repo root.

- `apps/budget_wise_app/` — the Flutter app (BudgetWise). Note: the Dart package name is `app_template`, so internal absolute imports are `package:app_template/...`.
- `packages/design_system_template/` — local design system package (`budgetwise_design_system`), exposing `AppTheme`. Consumed via path dependency.

## Commands

All commands run from `apps/budget_wise_app/`:

```bash
flutter pub get                                      # install deps
dart analyze lib --no-fatal-infos --fatal-warnings   # lint (exactly what CI runs)
flutter test                                         # run all tests
flutter test test/widget_test.dart                   # run a single test file
flutter run                                          # run on a connected device/emulator
flutter build web --release --base-href "/budgetwwise-app/"   # web build (note the doubled "w" in the path)
```

A `.env` file is **required** to run — it is loaded as a Flutter asset at startup via `AppConfig.initialize()`, and missing it will crash on launch. It is gitignored; see `.env.example`. Keys used: `BACKEND_TYPE` (`supabase` or `rest`), `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`, `DEBUG`.

CI (`.github/workflows/ci.yml`) runs analyze + test on PRs to `master`. Pushes to `master` deploy the web build to GitHub Pages (`deploy-web.yml`).

**Tests are required for new features.** CI runs `flutter test`, so add unit/bloc tests for new repositories, blocs, and business-rule logic (e.g. `PlanItem` status, actuals aggregation) rather than leaving them untested.

**Commit messages follow Conventional Commits** (`feat:`, `fix:`, …) — match the existing history.

## Domain model & business rules

The app helps a user budget a period and track spending against it. Core entities (see `lib/domain/entities/` and `lib/features/*/domain/entities/`):

- **Account** — a money source (cash, bank, …) with `openingBalance`, running `balance`, and `currency`.
- **Plan** — a dated budget period (`startDate`–`endDate`) with an optional `expectedIncome` and an `isActive` flag.
- **PlanItem** — a budget category inside a plan, with a budgeted `expectedAmount` and a computed `actualAmount`.
- **Transaction** — an `expense`, `income`, or `transfer`, tied to an `accountId` (plus `destinationAccountId` for transfers) and optionally tagged to a `planItemId`.

User flow: set up Accounts → create a Plan → add PlanItems → log Transactions against accounts/plan items. The home & plan tabs show progress per PlanItem; the insight tab is an AI chat over this data.

Intended business rules (preserve these when editing):

- **Single active plan.** Only one plan may have `is_active = true`; `setActivePlan` deactivates all others first (`plan_supabase_datasource.dart`).
- **Actuals are computed, never stored.** A `PlanItem.actualAmount` is derived at read time — `getPlanItemActuals` sums only **`expense`** transactions per `plan_item_id`; `getActualIncome` sums **`income`** transactions within the plan's date range. These are merged onto entities in the bloc layer, not persisted.
- **PlanItem status** (`lib/domain/entities/plan_item.dart`): `overBudget` when actual > expected; `nearLimit` at **≥ 85%** used; `noActivity` when actual is 0; otherwise `inProgress`.

## Architecture

### Two clean-architecture layouts coexist — know which one you're in

1. **Shared/root layout** at `lib/{core,data,domain}` — used by **auth** and **plans** (`Plan`, `PlanItem`). Datasources here have **both REST and Supabase implementations** (`lib/data/datasources/rest/` and `lib/data/datasources/supabase/`).
2. **Feature-first layout** at `lib/features/<feature>/{data,domain,presentation}` — used by newer features: `accounts`, `transactions`, `home`, `insight`. Each feature is self-contained with its own data/domain/presentation and is **Supabase-only**.

When adding a feature, follow layout #2. Repositories return `dartz` `Either` via the `ResultFuture<T>` / `Result<T>` typedefs in `lib/core/utils/typedefs.dart`; the left side is always a `Failure` (`lib/core/errors/failures.dart`).

### Backend switching

`BACKEND_TYPE` env var → `AppConfig` → `BackendConfig` (`lib/data/config/backend_config.dart`). `lib/di/injection.dart` branches on `BackendConfig.isSupabase` to register either Supabase or REST datasources. In practice the app runs on Supabase; most features only implement the Supabase path.

**The DB schema is not in this repo.** Before any schema-touching work (new tables/columns, queries, RLS), introspect the live project with the Supabase MCP tools (`list_tables`, `get_advisors`, etc.) rather than guessing column names or types.

### Dependency injection — manual get_it, not codegen

DI is wired **by hand** in `lib/di/injection.dart` (`configureDependencies()`, called from `main()`). Despite `injectable`/`injectable_generator` being in `pubspec.yaml`, there is **no `@injectable` annotation usage or generated `.config.dart`** — do not assume `build_runner` regenerates DI. Add new datasources/repositories/use-cases manually to `configureDependencies()`.

### State management is split by scope

- **Riverpod** for app-level concerns: the router (`appRouterProvider`) and theme (`themeModeProvider`). `main.dart` wraps the app in `ProviderScope`.
- **BLoC / Cubit** for feature-level state.

**BLoCs are NOT registered in get_it.** They are instantiated manually in `MainAppShell` (`lib/features/main/presentation/pages/main_app_shell.dart`) `initState`, pulling *repositories* from `getIt`, and exposed via `MultiBlocProvider`. The shell owns five long-lived blocs (home, active plan, account, transaction history, insight) across the five bottom-nav tabs, which are kept alive via an `IndexedStack`. Tab switches dispatch a `Refresh*` event to reload that tab's data.

### Navigation & auth

`go_router` (`lib/router/app_router.dart`) with a redirect guard driven by the **Supabase session** — unauthenticated users are sent to `/login`. The router refreshes on `Supabase.auth.onAuthStateChange`. Routes are minimal: `/login` (auth) and `/main` (the shell); in-app navigation is mostly tab/page based, not URL based.

### AI insight feature

`InsightChatCubit` (`lib/features/insight/presentation/bloc/insight_chat_cubit.dart`) calls the Supabase Edge Function **`budgetwise-gemini`** and persists chat to the `chat_messages` table (columns: `role`, `content`, `created_at`). It handles 429/503 as rate-limit errors. The Edge Function lives in the Supabase project (not in this repo).

## Gotchas

- `lib/di/injection.dart` defines a `_DevHttpOverrides` that **accepts all TLS certificates**. It is now installed only inside `if (kDebugMode)`, so release builds keep TLS verification — keep it that way. The block still `print`s the Supabase URL (the anon key is no longer printed).
- The web deploy `--base-href` is `/budgetwwise-app/` (doubled "w"); match it if editing deploy config.
- `apps/budget_wise_app/README.md` is the default Flutter template and is not authoritative.