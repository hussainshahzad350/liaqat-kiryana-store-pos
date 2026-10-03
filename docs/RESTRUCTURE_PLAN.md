# Liaqat Store POS Restructuring Plan

## 1. Purpose

This plan turns the current application into a maintainable, verifiable POS
without discarding the business rules that already exist. The default strategy
is **stabilize, isolate, then improve**. A full rewrite is not part of this plan.

The plan is deliberately incremental because sales, stock, cash, customer
credit, supplier balances, and reversals are financially sensitive. Each phase
must leave the application in a reviewable state and must be independently
reversible.

## 2. Non-negotiable boundaries

1. Preserve the existing SQLite schema unless a human explicitly approves a
   migration.
2. Treat money, stock, ledgers, sale cancellation, and purchase cancellation as
   protected behavior.
3. Capture current behavior in tests before refactoring protected behavior.
4. Separate UI, application-state, repository, and database changes into small,
   reviewable pull requests.
5. Never combine a visual redesign with a financial behavior change.
6. Keep English and Urdu, including RTL layouts, working in every UI phase.
7. Do not remove apparently unused code until runtime references, tests, and the
   product roadmap have all been checked.
8. A phase is complete only when its exit criteria have evidence; completing a
   code diff alone is not sufficient.

These rules complement `AI_CHANGE_GUARDRAILS.md`. If a required fix crosses a
layer boundary, it must first be split into an approved sequence of changes.

## 3. Target architecture

The restructuring will converge on four explicit layers without forcing a
big-bang directory rewrite:

| Layer | Responsibility | May depend on |
| --- | --- | --- |
| Presentation | Screens, dialogs, visual widgets, formatting, keyboard interaction | Application state and immutable view data |
| Application | BLoCs/controllers, commands, loading/error state, workflow orchestration | Repositories and domain types |
| Domain | Money/value objects, business vocabulary, behavior contracts | Dart only |
| Data | Repositories, SQLite mapping, transactions, backup/restore | Database and domain types |

During migration, existing feature folders remain valid. Files are moved only
when a human explicitly approves the rename and all imports/tests can be changed
atomically. The near-term goal is clear responsibilities, not cosmetic folder
purity.

## 4. Feature ownership map

| Feature | Current entry point | Protected dependencies | First restructuring goal |
| --- | --- | --- | --- |
| Authentication | `lib/screens/auth/login_screen.dart` | `PinAuthService`, secure storage | Extract presentation sections and test lockout/recovery states |
| Sales | `lib/screens/sales/sales_screen.dart` | `SalesBloc`, invoice, stock, cash and receipt repositories | Make the screen a composition root; preserve checkout behavior |
| Products | `lib/screens/product/product_screen.dart` | items, categories and units repositories | Standardize list/form states and remove duplicate presentation paths |
| Accounts | `lib/screens/accounts/accounts_screen.dart` | customer/supplier controllers and repositories | Standardize customer/supplier navigation and ledger presentation |
| Stock | `lib/screens/stock/stock_screen.dart` | stock and activity BLoCs/repositories | Separate overview, filters, activity details and actions |
| Purchases | `lib/screens/purchase/purchase_screen.dart` | purchase, items and supplier repositories | Lock transaction behavior with tests before UI work |
| Cash ledger | `lib/screens/cash_ledger/cash_ledger_screen.dart` | cash controller/repository | Standardize list states and transaction dialog |
| Settings | `lib/screens/settings/settings_screen.dart` | settings cubit/repository | Keep pages independent and verify backup/restore flows |
| App shell | `lib/widgets/app_shell.dart` | routes, sidebar state and feature providers | Define one navigation and responsive-layout contract |

## 5. Delivery phases

### Phase 0 — Establish a trustworthy baseline

**Goal:** Make the current state reproducible before changing behavior.

Tasks:

- [x] Record the restructuring strategy and protected boundaries.
- [x] Record the initial repository inventory and known verification gap.
- [x] Mark historical audit documents as snapshots rather than current truth.
- [ ] Install/use a Flutter SDK compatible with the lockfile.
- [ ] Run dependency resolution, localization generation, analysis, and all
      tests from a clean checkout.
- [ ] Launch a fresh desktop database and exercise the smoke-test checklist.
- [ ] Test an upgrade using a copy of an existing store database.
- [ ] Record failures without mixing fixes into the baseline commit.
- [ ] Add CI for formatting, analysis, and tests after the baseline is green.

Exit criteria:

- The exact Flutter/Dart versions are recorded.
- `flutter analyze` and `flutter test` have reproducible results.
- Fresh-install and existing-database smoke tests have recorded outcomes.
- Known failures have owners and severity rather than being hidden.

### Phase 1 — Protect business-critical workflows

**Goal:** Build a regression harness around existing behavior.

Add focused tests for:

1. cash, bank, credit, and mixed-payment sales;
2. walk-in overpayment and credit rejection;
3. insufficient stock and concurrent stock validation;
4. sale cancellation and exactly-once reversal entries;
5. purchases and purchase cancellation;
6. customer/supplier payment and balance updates;
7. backup, restore, and database upgrade behavior;
8. integer-money round trips and displayed totals.

Exit criteria:

- Every protected workflow has a named test and expected ledger/stock effects.
- Fixtures use isolated temporary databases.
- Tests check persisted outcomes, not only returned success values.

### Phase 2 — Establish the UI system

**Goal:** Improve consistency before redesigning individual screens.

Tasks:

- Define a small semantic token set for spacing, typography, color, radius,
  elevation, density, and focus states.
- Inventory shared buttons, form fields, dialogs, cards, tables, empty states,
  loading states, and error states.
- Define desktop breakpoints and the minimum supported window behavior.
- Define keyboard navigation and shortcut conventions for counter operation.
- Create English and Urdu/RTL visual test cases.
- Build a non-production component gallery or focused widget tests before
  replacing feature UIs.

Exit criteria:

- New screens do not introduce arbitrary colors or spacing.
- Shared components have light/dark and LTR/RTL examples.
- Focus, hover, disabled, loading, validation, and error states are specified.

### Phase 3 — Sales vertical slice

**Goal:** Prove the restructuring method on the most important workflow.

Order of work:

1. Capture current sales behavior and screenshots.
2. Document `SalesBloc` inputs, outputs, and repository contracts.
3. Reduce `sales_screen.dart` to layout, event forwarding, and composition.
4. Keep calculations and persistence outside visual widgets.
5. Redesign product selection, cart, customer selection, totals, payment, and
   recent-sales states using the UI system.
6. Verify keyboard-only checkout and Urdu/RTL behavior.
7. Compare persisted invoices, stock, cash, and ledger entries before/after.

Exit criteria:

- No protected persisted outcome changes.
- The sales screen has explicit loading, empty, error, and success states.
- The complete checkout flow works with mouse and keyboard.
- Before/after screenshots and test evidence are attached to the PR.

### Phase 4 — Remaining features, one slice at a time

Recommended order:

1. Products (items, categories, units)
2. Accounts (customers, suppliers, ledgers)
3. Stock and purchases
4. Cash ledger
5. Settings, backup, and security
6. Authentication and app shell polish

Each slice repeats the same sequence: baseline tests, responsibility map,
presentation-only restructuring, visual verification, workflow verification,
then cleanup.

### Phase 5 — Deliberate cleanup

**Goal:** Remove confirmed debt after the application is stable.

Tasks:

- Re-run unused-symbol and call-site audits.
- Classify candidates as active, planned, compatibility-only, or removable.
- Remove dead code in small feature-scoped changes.
- Replace stale audit reports with automated checks where practical.
- Update onboarding, architecture, release, backup, and recovery documentation.
- Measure startup, search, checkout, large-list, and backup performance.

Exit criteria:

- Documentation describes the code that actually ships.
- No known duplicate feature entry points remain.
- Critical workflows pass on the release build and a realistic data copy.

## 6. Pull request and commit policy

Every restructuring PR should include:

- the feature and layer being changed;
- an explicit statement about schema and protected behavior impact;
- tests/checks run and any environment limitations;
- screenshots for perceptible UI changes;
- migration and rollback notes where relevant;
- a small diff that can be reviewed without unrelated formatting churn.

Suggested commit prefixes are `docs:`, `test:`, `refactor:`, `fix:`, and
`style:`. A refactor commit must not silently contain behavior changes.

## 7. Manual smoke-test checklist

Run this checklist on a disposable database first and on a backup copy of real
data before a release:

- [ ] Log in, log out, trigger lockout, and complete recovery.
- [ ] Create/edit/archive a product, customer, and supplier.
- [ ] Complete cash, bank, credit, and mixed-payment sales.
- [ ] Reject an invalid payment and an insufficient-stock sale.
- [ ] Cancel a sale once; verify a second cancellation cannot duplicate effects.
- [ ] Create and cancel a purchase.
- [ ] Record customer and supplier payments.
- [ ] Adjust stock and inspect its activity history.
- [ ] Add cash-in and cash-out entries and verify displayed balance.
- [ ] Print/export a receipt in English and Urdu.
- [ ] Create a backup, restore it, and compare record counts and balances.
- [ ] Resize to the minimum window size and navigate using only the keyboard.

## 8. Decision log

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-10-03 | Repair incrementally; do not rewrite | Existing domain behavior, migrations, repositories, and tests have substantial value |
| 2026-10-03 | Begin with documentation-only Phase 0 | The current environment has no Flutter executable, so claiming a green runtime baseline would be misleading |
| 2026-10-03 | Use Sales as the first vertical slice | It exercises the greatest concentration of stock, cash, ledger, customer, and receipt behavior |
