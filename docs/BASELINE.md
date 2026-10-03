# Repository Baseline

**Captured:** 2026-10-03

**Branch:** `work`

**Purpose:** Phase 0 evidence for the incremental restructuring plan.

## Current inventory

- 217 Dart files under `lib/`, `test/`, and `integration_test/` (when present).
- 23 files matching `test/**/*_test.dart`.
- 485 textual `group`, `test`, or `testWidgets` declarations in `test/`.
- Approximately 33,823 non-generated lines of Dart under `lib/`.
- Application composition uses repositories plus BLoC/Provider from
  `lib/main.dart`.
- SQLite schema version is 5 and foreign-key enforcement is enabled when the
  database opens.

Counts are orientation metrics, not quality or coverage measurements. Generated
localization Dart files are excluded from the source-line estimate.

## Largest non-generated source files

| Lines | File |
| ---: | --- |
| 881 | `lib/core/database/database_helper.dart` |
| 857 | `lib/screens/sales/sales_screen.dart` |
| 851 | `lib/screens/customers/widgets/customer_ledger_panel.dart` |
| 844 | `lib/screens/items/items_screen.dart` |
| 795 | `lib/core/repositories/items_repository.dart` |
| 795 | `lib/core/repositories/invoice_repository.dart` |
| 681 | `lib/core/repositories/customers_repository.dart` |
| 671 | `lib/screens/suppliers/widgets/supplier_ledger_panel.dart` |
| 650 | `lib/core/repositories/dashboard_repository.dart` |
| 634 | `lib/bloc/sales/sales_bloc.dart` |

File length identifies review candidates but does not, by itself, justify a
split. Each candidate needs a responsibility and dependency review first.

## Verification status

The container used to capture this baseline does not have `flutter` on `PATH`.
Consequently, dependency resolution, generated-localization validation, static
analysis, tests, desktop launch, and screenshots have **not** been verified in
this baseline.

Required commands in a Flutter-capable environment:

```bash
flutter --version
dart --version
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build linux --debug
```

Use the appropriate desktop build target on Windows or macOS. Record the SDK
versions, command outputs, and any failing test names here before beginning
Phase 1.

## Known documentation drift

- The root README previously described the application as
  "production-ready" despite the absence of a verified baseline in this
  environment.
- The README previously reported zero test coverage even though the repository
  contains a substantial test suite. Test-file/declaration counts do not prove
  coverage; measured coverage is still unknown.
- `repository_audit.md` and `repository_audit_tasks.md` are historical audit
  snapshots and may mention entry points that subsequent commits removed.

## Baseline change rule

Do not silently update this document to make the baseline appear green. Append
new dated verification results, and link fixes to their commit or pull request.

## 2026-10-03 Windows working-tree verification

This is additional evidence, not a replacement for the original snapshot.
Checked `master` at `7be6e32` in `C:\src\project\liaqat-kiryana-store-pos`.
The checkout already contained local changes to the sales screen, lockfile,
test concurrency configuration, and generated plugin files, plus an untracked
backup patch. Results therefore do not establish a clean-checkout baseline.

Installed SDK: `C:\src\flutter\bin`. Its cached `flutter.version.json` records
Flutter **3.44.4**, stable, framework revision
`ad70ec4617166f1c38e5d2bfd388af71fda14f06`, and Dart **3.12.2**.
The direct `flutter --version` command produced no output and was interrupted;
these versions come from the SDK metadata, not successful command output.

| Check | Observed result |
| --- | --- |
| `flutter analyze` | Exit 0; no issues found; reported duration 86.5 seconds |
| `flutter test` | Exit 1; 381 passed, eight failures; reported test duration 51 seconds |
| `dart format --output=none --set-exit-if-changed lib test` | No output before interruption; unverified |
| `flutter gen-l10n` | No output before interruption; unverified |
| Explicit dependency resolution | Not run separately; clean-checkout reproduction remains pending |
| Windows build and desktop smoke checks | Not performed in this continuation |
| Existing-store database upgrade | Not performed; requires a disposable copy |

The suite used the existing `dart_test.yaml` with `concurrency: 1`.
Additional attempts to capture complete test output did not produce output
before interruption. No fixes were mixed into this baseline capture.

### Failure triage

Owners below are proposed work areas, not assigned people. Severity describes
the verification impact; these results do not prove production failures.

| Failure | Evidence / impact | Severity | Proposed owner |
| --- | --- | --- | --- |
| Repository integration setup and teardown | `repository_test.dart:22` reads an uninitialized `databaseFactory`; teardown then throws `LateInitializationError`; integration workflows do not run | High: protected workflow verification blocked | Test infrastructure |
| Purchase repository setup and teardown | Full-suite failure summary names both hooks; source reads the factory before assigning the FFI factory | High: purchase verification blocked | Test infrastructure |
| Product screen setup and teardown | `product_screen_test.dart:36` has the same uninitialized factory error and teardown failure | High: product workflow verification blocked | Test infrastructure |
| Settings dashboard category count | `settings_screen_test.dart:76` expects four `SettingsTile` widgets; five are rendered | Medium: expectation needs review against current UI | Settings tests |
| One additional failure | Eight failures total; seven are identified above. The intermediate output was truncated, so the remaining failure must be captured before proposing its fix | Untriaged | Baseline verification |

Phase 0 remains open. Next work is the bounded sequence in
`RESTRUCTURE_PLAN.md`; application refactoring and CI promotion remain gated
on complete evidence. Database fixtures must be verified as isolated before
repairing setup: the current repository tests call `resetDatabase()` and must
not be redirected to a live store database.

## 2026-10-03 test infrastructure repair

Scope: test code and verification documentation only. Existing application,
lockfile, and platform-file changes remain outside this repair. No production
schema, repository, stock adjustment, or money calculation was modified.

The complete original run confirmed **381 passed / eight failures**. The
previously unidentified failure was `SettingsCategory has expected 5 values`:
the current enum has six values, including Security. Three database suites
failed in both setup and teardown; the two settings failures were stale counts.

### Repairs and regression protection

- `test/support/test_database.dart` installs a dedicated FFI factory with a
  unique system temporary directory before any database reset. It checks the
  path, recreates the database before each test, closes the connection, restores
  the previous nullable factory, and removes only its generated directory.
- Repository and product widget suites use that fixture. No test reset touches
  the normal desktop store path.
- Sales/purchase fixtures explicitly create matching stock events and cached
  quantities. The customer-payment fixture supplies its opening ledger entry.
  These fixtures describe a consistent store; they do **not** repair or verify
  the application's sample-data initialization.
- Purchase tests await exception assertions before checking persisted results.
  They verify that repeated cancellation produces exactly one stock reversal
  and one supplier-ledger reversal, and that failed multi-item cancellation
  leaves the purchase completed with no reversal entries and unchanged stock.
- Negative-stock expectations use the existing repository error `NEGATIVE_STOCK`.
  The former `INSUFFICIENT_STOCK_FOR_CANCELLATION` expectation predates the
  current event-based implementation. The rejection and rollback expectations
  remain intact.
- Settings tests include the Security category and verify that its tile opens
  that category.

### Verification results

| Check | Result |
| --- | --- |
| `flutter --version` / `dart --version` | Exit 0; Flutter 3.44.4 stable / Dart 3.12.2, Windows x64 |
| `flutter pub get --enforce-lockfile` | Exit 0; existing lockfile resolves |
| `flutter gen-l10n` | Exit 0; reports 14 untranslated Urdu messages |
| `flutter analyze` | Exit 0; no issues; 19.8 seconds |
| `flutter test --reporter expanded` | Exit 0; **420 tests passed**, zero failures; 45 seconds |
| Formatting of changed test files | Applied; changed files formatted |
| Global format dry run | Exit 1; 99 of 225 files would change; `--output=none` left files untouched |
| `git diff --check` | Passed |

Local ignored logs retain the complete runs: `baseline-tests.log`,
`baseline-repair-tests.log`, `baseline-tests-after.log`, `baseline-analyze.log`,
and `baseline-format.log`. These are working-tree results, not clean-checkout
evidence. The higher passing count reflects previously blocked suites now
executing plus the new Security navigation test.

### Production findings exposed by the running tests

These findings remain open even though the repaired test suite passes.

| Finding | Evidence | Severity / next work area |
| --- | --- | --- |
| Fresh sample product has cached stock without matching events | Database creation seeds product 1 with stock 45; unmodified sales/purchase tests then throw `STOCK_INCONSISTENCY_REPORTED`. Consistent fixtures require an explicit opening stock event. | High; database initialization / financial behavior review |
| Customer opening balance is not accompanied by a ledger entry | Creating a customer with balance 100000 then calling `addPayment` throws `CUSTOMER_BALANCE_MISMATCH` unless the fixture supplies an opening ledger entry. | High; customer repository / accounting review |
| Unit normalization uses double-quoted SQL values | Fresh database opens log `no such column: "Weight"` for `UPDATE unit_categories SET name = "Weight" WHERE id = 1`; the normalization method catches and logs the error. | High; separate database-layer SQL compatibility fix |
| Urdu localization gaps | Localization generator reports 14 missing translations. | Medium; localization work |
| Global formatting drift | 99 files fail the SDK's formatting check. | Low; dedicated formatting change before CI enforcement |

Before approving a production repair, capture the intended opening-event and
ledger behavior in focused regression tests. Do not weaken consistency checks
or silently rewrite existing-store balances to make these findings disappear.
Fresh desktop smoke testing, copied-store upgrade/restore testing, and a clean
checkout run remain outstanding; Phase 0 and the CI gate remain open.

## 2026-10-03 unit normalization compatibility fix

Following the test-infrastructure repair, a separate database-layer change
replaced four double-quoted SQL values in
`DatabaseHelper.ensureStandardUnitsInTransaction` with bound parameters.
The category IDs and intended names are unchanged. This fixes SQL execution
with the locked SQLite runtime; it does not modify schema or financial rules.

`test/integration/unit_normalization_test.dart` reproduced the original
`no such column: "Weight"` failure before the fix. After the fix, it verifies
that edited category names are restored, existing unit IDs are retained,
repeated normalization is idempotent, and `sqlite_master` is unchanged.
It calls the transaction implementation directly so the logging wrapper cannot
hide a failing SQL statement.

Final verification on the current working tree:

| Check | Result |
| --- | --- |
| Normalization regression before fix | Failed with the expected SQLite quoting error |
| Normalization regression after fix | Passed |
| Full test suite | **421 passed**, zero failures; exit 0; 65 seconds |
| Static analysis | No issues; exit 0; 13.9 seconds |
| Windows debug build | Exit 0; built `build/windows/x64/runner/Debug/liaqat_kiryana_store_pos.exe`; 41.8 seconds |
| Seven added/edited test files, format check | Zero changes; exit 0 |
| Diff whitespace check | Passed |
| Full-suite log scan for normalization errors | No matches |

Evidence is in the local ignored logs `baseline-normalization-before.log`,
`baseline-normalization-after.log`, `baseline-tests-final.log`,
`baseline-analyze-final.log`, and `baseline-windows-build-final.log`.
The earlier build also passed before this SQL fix (61.2 seconds).

The SQL quoting finding is resolved. The two financial initialization findings,
global formatting drift, untranslated Urdu messages, clean-checkout verification,
and manual fresh/copied-database smoke checks remain open. A successful build
and test run do not establish that a real store can safely upgrade or transact
with the current opening balances.

## 2026-10-03 fresh-database opening records

The next database-layer repair addresses sample-data initialization in
`DatabaseHelper._insertSampleData`. It preserves the existing stock quantity
of 45 and customer balance of 250000 paisas, and creates the records that
explain those values:

- One initial `stock_adjustments` row and its matching `stock_activities` event,
  using the same reference and transaction-identity convention as product
  creation in `ItemsRepository`.
- One opening customer ledger adjustment with debit/balance 250000, credit 0,
  a stable transaction identity, and a UTC timestamp.

Schema version remains 5. This initializer runs when a database is created;
it does not backfill, reset, or rewrite an existing store. Sale, purchase,
payment, and reversal implementations remain unchanged.

`test/integration/fresh_database_test.dart` uses only temporary-directory
isolation; it does not repair stock or ledger fixtures. Before the fix, all
four tests failed: event totals were missing, sale/purchase creation reported
`STOCK_INCONSISTENCY_REPORTED`, and payment reported
`CUSTOMER_BALANCE_MISMATCH`. After the fix they verify:

1. Seeded quantities/balances match their events, opening records occur once,
   schema version is unchanged, and foreign keys are valid.
2. A cash sale reduces stock and persists cash inflow; cancellation restores
   stock and creates exactly one cash reversal despite a second attempt.
3. A purchase increases stock and supplier balance; cancellation restores both.
4. A customer payment persists its receipt and reduces both cached and ledger
   balance from 250000 to 200000 paisas.

The full suite exposed a pre-existing fixture collision: the outstanding-total
test reused the seeded customer's unique phone number, triggering
`INSERT OR REPLACE`. With the opening ledger present, foreign-key enforcement
correctly prevents that replacement. The test now uses distinct phone numbers
and verifies an exact 125000-paisa increase over the initial total.

Working-tree verification: **425 tests passed**, zero failures (41 seconds);
static analysis passed with no issues (13.6 seconds); Windows debug build passed
(39.6 seconds); changed test formatting and diff whitespace checks passed.
Local ignored evidence: `baseline-fresh-before.log`, `baseline-fresh-after.log`,
`baseline-seed-suite-final.log`, `baseline-seed-analyze.log`, and
`baseline-seed-build.log`.

The fresh sample-data inconsistency is resolved. The separate
`CustomersRepository.addCustomer` path for a nonzero opening balance still
needs a repository-layer repair and dedicated tests. Existing stores with
missing historical events require diagnosis using a backup copy; the fresh
initializer intentionally does not infer their history.

### Fresh-checkout reproduction

Created a separate managed worktree at commit
`7be6e327bae2ec705ca13b51e9be43d339c97043`, then applied the current candidate
files, including the pre-existing sales-screen, lockfile, and test-configuration
changes. The new checkout had neither `.dart_tool` nor `build` before validation.
This verifies the candidate, not unmodified HEAD; no project caches were copied.
The installed SDK and machine package cache were reused.

- `flutter pub get --enforce-lockfile`: exit 0.
- `flutter gen-l10n`: exit 0; the same 14 untranslated Urdu messages remain.
- `flutter analyze --no-pub`: exit 0; no issues; 14.6 seconds.
- `flutter test --no-pub --reporter expanded`: exit 0; **425 passed**; 48 seconds.
- SHA-256 comparison confirmed all 12 changed/new code, test, lockfile, and test
  configuration files matched the primary checkout exactly.

The worktree was submitted for archival after verification. All evidence logs
were written directly into the primary checkout (`baseline-clean-pub.log`,
`baseline-clean-l10n.log`, `baseline-clean-analyze.log`,
`baseline-clean-tests.log`) and remain available there.

The candidate's fresh-checkout verification gate is complete. This automated
repository coverage does not replace desktop interaction, backup/restore, or
upgrade checks on a copy of real store data.

## 2026-10-03 customer opening-balance transaction

The repository-layer continuation changes only `CustomersRepository.addCustomer`
in production. It saves the customer and any nonzero opening ledger adjustment
in one transaction. Positive balances are debits, negative balances are credits,
and the signed cached balance is preserved. The opening entry uses the supplied
customer creation timestamp in UTC and identity `CUSTOMER:<id>:INITIAL`.
Zero balances create no ledger entry. Opening balances do not create receipts
or cash movements.

Customer inserts now use `ConflictAlgorithm.abort` instead of `replace`.
An existing ID or unique phone number therefore raises a database error rather
than deleting/replacing a customer. This is deliberate creation behavior;
the existing `updateCustomer` method remains the editing path. No schema,
payment/reversal implementation, or historical customer row was modified.

The new `test/integration/customer_opening_balance_test.dart` has eight cases:

- Positive and negative opening balances have exactly one matching entry.
- Zero opening balance creates no financial entry.
- Subsequent payments preserve ledger/cache equality for both balance signs.
- A temporary test trigger forces ledger insertion to fail and verifies that
  the customer and ledger tables remain identical to their pre-call state.
- Duplicate phone and ID attempts leave existing customer/ledger rows intact.

Before the fix, seven cases failed and only the zero-balance case passed.
After the fix, all eight pass; together with the existing repository integration
suite, all 34 focused cases pass. The existing payment integration test now uses
the real opening-entry implementation. Its manual seed helper was removed after
confirming that no callers remained.

Verification: **433 tests passed**, zero failures (53 seconds); analysis passed
with no issues (7.7 seconds); all three changed test/helper files pass formatting.
Windows debug build passed (58.3 seconds), and diff whitespace checks passed.
Local ignored logs: `baseline-customer-before.log`, `baseline-customer-after.log`,
`baseline-customer-suite.log`, `baseline-customer-analyze.log`, and
`baseline-customer-build.log`.
The previous fresh-checkout result covers the preceding 425-test candidate;
this continuation's results are from the main working tree.

Both identified creation-time consistency defects are now repaired. Existing
store inconsistencies still need diagnosis on a copy: the new creation paths
do not infer missing historical events or rewrite balances.

## 2026-10-03 Urdu completion and formatting cleanup

Added the 14 missing translations to `lib/l10n/app_ur.arb` and regenerated
`app_localizations_ur.dart`. The new Urdu text covers activity, today's customers,
unit viewing/code entry, numeric validation, stock availability/limits, required
description, and negative-price errors. English keys and placeholders are
unchanged. Comparing the English and Urdu key sets now reports zero missing
Urdu keys, and `flutter gen-l10n` completes without untranslated-message warnings.

After localization generation, saved all 228 Dart files under `lib/` and `test/`
before running the SDK formatter. `dart format lib test` changed 99 files.
The subsequent `dart format --output=none --set-exit-if-changed lib test`
passed with zero changes. This was a mechanical formatting pass; no manual
application edits were mixed into it.

The local ignored review snapshot is
`build/restructure-format-c1f25b9e46154e728824329fa1c21f66/`. It contains
`before/`, `after/`, the complete file list, `formatted-files.txt`, and
`formatting-only.patch`. The snapshot was taken after the earlier fixes and
localization generation, so its diff isolates formatting from functional work.
Existing uncommitted changes were preserved. The root Git diff still includes
those earlier changes; it is not itself a formatting-only diff.

Evidence logs: `baseline-urdu-generation.log`, `baseline-format-applied.log`,
and `baseline-format-verified.log`.
