# Phase 1 — Protected workflow regression harness

This coverage map defines the persisted contracts that later restructuring must
preserve. It complements `RESTRUCTURE_PLAN.md` and the Phase 0 baseline; it does
not replace repository assertions with mock return values or UI success messages.

**Complete — 2026-10-04:** 35 focused tests pass; the phase-end suite passes
522 tests with the existing optional store-copy check skipped. Analysis reports
no issues and all 260 Dart files pass formatting. Evidence is recorded in the
Phase 1 closeout section of `BASELINE.md`.

## Isolation and execution

Repository suites use `test/support/test_database.dart`: each suite installs a
SQLite FFI factory pointing at a generated temporary directory, and each test
recreates its database. Both the factory directory and opened database path are
asserted before operations. Teardown closes the helper, restores the prior
factory and removes only the fixture directory. Historical and restore fixtures
also live there. No protected-workflow test uses the normal store database.

`dart_test.yaml` runs suites serially because the singleton database helper and
factory are process-wide. Within a test, concurrent repository calls intentionally
share the same SQLite connection to exercise competing application commands.
This covers transaction serialization in the current single-process desktop
app; it does not claim independent multi-process or distributed concurrency.

The new `test/integration/protected_workflows_test.dart` has **26 cases**.
Two additional `money_test.dart` cases cover paisa round trips and display.
Existing tests below remain mandatory rather than being duplicated.

## Required workflow coverage

| Plan requirement | Named test / suite | Required persisted outcome |
| --- | --- | --- |
| Cash, bank, credit and mixed sales | `protected_workflows_test.dart`: each `<mode> sale posts exact paisas and linked reversals` | Rs 100.01 invoice; stock 45→44; CASH/BANK entries equal the paid portions; named-customer debit/cache equal only credit. Mixed split is 3333/3333/3335 paisas. |
| Walk-in overpayment | `invoice_accounting_invariants_test.dart`: `walk-in overpayment records only the invoice total as inflow` | Tendered 12000 against 10000 records only 10000 as inflow. Native checkout validation also verifies displayed change. |
| Walk-in credit/underpayment; named overpayment | `protected_workflows_test.dart`: named rejection cases | Error code matches; every application table's rows are identical before/after. |
| Negative payments and credit limit | `protected_workflows_test.dart`: `negative payment`, `credit limit exceeded` | Rejection preserves invoices, items, stock, customer cache and all ledgers. Credit-limit case otherwise has matching invoice/payment totals. |
| Insufficient stock | `invoice_accounting_invariants_test.dart`: `insufficient stock rolls back the invoice and all ledger writes`; new later-item rollback case | No partial header, item, cash or stock writes, including when an earlier item already reduced stock inside the transaction. |
| Concurrent stock validation | `protected_workflows_test.dart`: `competing checkouts cannot oversell the same stock` | Two requests for six units against ten: exactly one invoice/item/inflow, one insufficient-stock rejection; cache and stock-event sum both four. |
| Sale cancellation and exactly-once effects | All four new payment-mode cases and `competing cancellations produce exactly one reversal` | Stock restored; customer credit removed; each cash/customer/stock reversal links to its original row with the original amount/mode. Repeated/concurrent cancellation cannot duplicate reversals. |
| Purchases and cancellation | `fresh_database_test.dart`, `purchase_repository_test.dart`; new `purchase reversal links original events and preserves later payments` | Purchase adds stock and supplier debt. Return restores stock, links original stock/supplier rows, and preserves a later 3333-paisa supplier payment, leaving a -3333 balance and unchanged cash payment. |
| Consumed purchased stock | `protected_workflows_test.dart`: `purchase cancellation rejects consumed stock without partial reversal` | A real intervening sale consumes the purchased unit; return rejects negative stock and preserves the completed purchase and all table rows. |
| Customer/supplier payments | New CASH/BANK customer payment cases; supplier payment/return case; `customer_opening_balance_test.dart`, `account_crud_balance_test.dart` | Receipt/payment row, ledger credit and cash IN/OUT carry exact paisas; caches match current ledger balances. Zero/negative payments preserve every row. |
| Backdated and mixed-format balances | `customer_payment_date_order_test.dart`, `ledger_append_order_test.dart` | Current running balances follow append order for receipts, sales, purchases, payments and reversals; dates do not overwrite later balance effects. |
| Atomic failures and retry | New final-ledger failure cases for sale, purchase and both payment types; sale/purchase reversal failure cases | Triggered final write failure rolls back all prior transaction rows/caches. Failed reversal leaves the completed event intact and succeeds after the injected fault is removed. |
| Backup | `backup_repository_test.dart` (five cases) | Consistent read-only backup, committed WAL inclusion, unique names, correct retention, unrelated files preserved. |
| Restore | `restore_repository_test.dart` (eleven cases), `database_lifecycle_test.dart` | All backed-up table rows preserved, reopened connection and foreign keys enabled, invalid sources rejected, emergency rollback on failed upgrade, overlapping restores excluded. |
| Upgrades | `historical_upgrade_test.dart` (nine cases), frozen schema fixtures v1–v4 | Upgrade to v5 on open and restore; all prior stored columns/rows retained, valid transaction identities, integrity/foreign-key checks pass, source backup unchanged, reopen stable. |
| Integer-money round trips/display | `money_test.dart` new round-trip/display cases; saved discounted invoice case; `repository_test.dart` | Paisas survive input/decimal round trips including negative balances. Display retains cents/grouping/sign; 10001−125 persists subtotal 10001, discount 125, payable 9876 and displays Rs 98.76. Monetary SQLite columns remain INTEGER. |
| Fractional quantities | `invoice_accounting_invariants_test.dart`, `receipt_export_test.dart` | Saved 1.5-unit invoices retain quantity and exact posted paisas; exported receipts preserve the financial records. |

Whole-table snapshots exclude SQLite's internal tables and compare rows in rowid
order. Fault-injection triggers are created only in disposable fixtures and do
not modify the production schema. Stock fixtures always have matching events.
Failure tests assert actual repository behavior, transaction rollback and row
identity rather than merely exceptions. Foreign-key checks accompany successful
posting and failure/retry cases.

## Repeatable checks

Use Flutter 3.44.4 / Dart 3.12.2, with locked dependencies already resolved:

```powershell
# Focused development gate
flutter test --no-pub test/integration/protected_workflows_test.dart test/unit/money_test.dart

# Phase exit; run the full suite once after focused checks
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --no-pub
flutter test --no-pub
```

The Windows CI workflow already runs the entire repository suite; discovery
includes the new test file automatically. Phase 1 changes tests and documentation
only. Phase 0 desktop screenshots, the successful ordinary executable and native
evidence remain applicable; no UI, application, repository or schema changes
require another desktop build in this phase.

The user-waived physical printer and populated-store checks remain explicit in
`BASELINE.md`. A synthetic historical upgrade is not proof about an unverified
real store. No new waivers are needed for the Phase 1 regression harness.
