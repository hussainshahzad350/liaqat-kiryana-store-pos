# Repository Baseline

**Captured:** 2026-10-03

**Branch:** `work`

**Purpose:** Evidence for the incremental restructuring plan.

**Current status — 2026-10-04: Phases 0 through 5 complete under retained waivers.**
The latest full suite passes 505 tests with one optional store-copy check skipped.
Compiled AOT release workflows and synthetic-volume measurements pass; all 69
Phase 5 protected implementation hashes remain unchanged. The ordinary Windows
release application is restored. Phase 4 retains passing evidence for 38 native
debug scenarios across its matrix and repairs. Physical printing and actual
populated-store validation remain explicitly waived. Earlier results below are
historical snapshots; see each closeout for its exact scope.

## Phase 5 closeout — 2026-10-04

Deliberate cleanup removes three zero-caller presentation/empty helpers, retains
16 explicitly classified planned/compatibility libraries and leaves all 69
captured protected implementations unchanged. Source audit finds 195
production-reachable libraries and no duplicate screen declarations. Route aliases
continue to delegate to the canonical Product and Accounts implementations.
README and the old function/task audit reports now describe current source;
onboarding, architecture, release and backup/recovery guides record actual
contracts. CLEANUP_AUDIT.md provides deletion rationale and rollback references.

| Gate | Result | Local evidence under build/ |
| --- | --- | --- |
| Source inventory | 16 reviewed candidates; zero classification drift; no duplicate screens | baseline-phase5-audit.log; cleanup-phase5-review/audit-after.json |
| Focused audit/fixture | Three cases pass | baseline-phase5-focused-final.log |
| Protected implementation comparison | 69 hashes unchanged | baseline-phase5-protected.log; cleanup-phase5-review/protected-before.json |
| AOT release workflows | Pass on isolated copied synthetic volume; source hash unchanged; all saved tables match after restore | cleanup-phase5-review/release-smoke.json; baseline-phase5-release-verification.log |
| Performance | Seven warm samples per operation plus native startup/checkout observations | PERFORMANCE.md; raw release-smoke.json |
| Full phase-end suite | **505 passed, one optional store-copy check skipped**, 114 seconds | baseline-phase5-full-suite.log |
| Analyzer | No issues, 4.9 seconds | baseline-phase5-analyze-final.log |
| Formatting | 283 Dart files; zero changes | baseline-phase5-format-final.log |
| Tooling/CI configuration | PowerShell parses; YAML parses with audit/release gates | baseline-phase5-tooling-validation.log |
| Normal release application | Shipping lib/main.dart target built successfully in 58.4 seconds after harness | baseline-phase5-release-build.log |
| Whitespace | Staged/unstaged checks pass | baseline-phase5-whitespace.log |

The test count changes from 557 to 505 because 55 obsolete Markdown-content
assertions were replaced by two live graph/manifest cases and one fixture-integrity
case. Existing financial, stock, backup, localization and widget tests remain.
The full VM suite ran once at phase exit; SQLite/build targets ran serially.
The prior 38-case native debug matrix remains Phase 4 evidence; it is not presented
as an AOT keyboard test. No active presentation implementation changed here.

Release checks use explicit exceptions, not compiled-out assertions. The separate
AOT target invokes actual PIN/search/cart/cash checkout callbacks and checks four
payment/reversal modes, payments, purchase/cancellation, stock adjustments, cash
in/out, integrity and full backup/restore row equality. The 2.29-MiB source copy
contains 10,001 products, 2,002 customers after checks and 50 historical cancelled
invoices before startup. Generated stock/contact distributions are deliberately
labeled synthetic. This is volume evidence, not actual store-copy provenance.

Recorded repairs/limitations:

- The first release execution exposed duplicate contact numbers in generated
  customers. Unique fixture numbers repair it; the fixture test verifies seed
  preservation, unique contacts, counts, zero opening stock and foreign keys.
- Harness repeat-cancel checks were aligned with existing rejection codes, with
  unchanged stock-event rows. Product selection uses the real search callback
  rather than assuming the stocked item is the first tile in a large catalog.
- Initial analyzer warnings about verification-only preference mocks were fixed
  by locating those calls in the test-support fixture. Flow-control blocks were
  corrected; final analysis is clean without source-warning suppression.
- Analysis overlapped VM listener generation inside build/phase5-temp and flagged
  the generated listener's transitive imports. analysis_options now excludes
  generated build output; lib/test/integration_test/tool remain analyzed.
- Release and CI scripts parse locally. Hosted CI, native credential persistence,
  physical printing, other OS targets and actual store data are not claimed.

The Windows integration runner forces debug builds in the verified SDK; the new
release executable runs without a VM service. verify_release.ps1 checks success
and rebuilds the ordinary release entry point in its finally block. The earlier
physical-printer/populated-store waivers remain. All six plan phases are closed
within that amended scope; no additional restructuring phase is queued.

## Phase 4 closeout — 2026-10-04

All remaining desktop features adopt the shared presentation boundary. Products
and Accounts share their title/tab frame; dense category panes scroll horizontally
instead of overflowing; stock/catalog and unit rows allow real Urdu font metrics.
Catalog loading/paging failures and cash errors expose localized retry. Existing
providers, events, paging/filter rules, conversions and persistence remain owned
by their original implementations. See REMAINING_FEATURES.md for the map.

All 62 protected implementation hashes match the phase-start snapshot. Native
category/unit editing compares system units and twelve protected tables; retained
account, stock, purchase, payment, cancellation and backup/restore checks validate
persisted outcomes on isolated disposable databases.

| Gate | Result | Local evidence under build/ |
| --- | --- | --- |
| Focused widget/unit regression | 79 passed, including eight new locale/brightness retry cases | baseline-phase4-focused-verified.log |
| Focused native layouts/taxonomy | Six passed in 58 seconds; 40 after screenshots | baseline-phase4-native-focused.log; remaining-phase4-review/ |
| Complete desktop matrix | 38 distinct scenarios have passing evidence across the aggregate and repairs | baseline-phase4-native-final.log; baseline-phase4-native-repair.log; baseline-phase4-native-keyboard-final.log |
| Protected implementations | 62 hashes unchanged | baseline-phase4-protected.log; remaining-phase4-review/protected-before.json |
| Phase-end full suite | **557 passed, one optional store-copy check skipped**, 126 seconds | baseline-phase4-full-suite.log |
| Analysis | No issues, 14.8 seconds | baseline-phase4-analyze-final.log |
| Formatting | 282 Dart files; zero changes | baseline-phase4-format-final.log |
| Localization generation | Three generated files identical across two runs; formatting enabled in l10n.yaml | baseline-phase4-localization.log |
| Normal Windows debug build | Passes; ordinary application executable restored | baseline-phase4-build.log |
| Whitespace | Staged and unstaged checks pass | baseline-phase4-whitespace.log |

Failures and repairs are retained rather than presented as a green first run:

- Baseline native collection exposed category overflows at the minimum width.
  Initial fixture issues included an uninitialized window handle and an invalid
  hit-test requirement on transparent screen centers. Thirty-six before captures
  remain; English cash/settings baseline captures are absent. Strict after-mode
  layout checks and all four language/brightness visual cases pass.
- Initial migration analysis caught a partial toolbar style extraction and error
  argument types. These were corrected before the 79-case focused check. An
  initial test command also included three nonexistent paths; the corrected
  command and result are recorded in the verified focused log.
- The first complete desktop run passed 35 of 38 cases in 6m58s. A checkout test
  sent F9 before asynchronous cart loading completed; the bounded cart wait now
  checks the rendered result. Native window focus suspension also broke Urdu Tab
  traversal; the fixture restores the window without assigning widget focus.
- Urdu product editing revealed a 1.7-pixel unit-dropdown overflow. Expanded
  selectors and a single-line unit label repair it without changing values.
  The focused payment/keyboard/product rerun passed 11 of 12 cases in 3m22s;
  its remaining navigation assertion tested an empty screen center for pointer
  hits. The assertion now checks the active, laid-out route; all Tab and Enter
  interactions remain. The final keyboard target passes all four cases in 2m02s,
  including English/Urdu checkout, navigation and backup/restore. Both product
  CRUD cases and all payment cases pass in the repair run.
- Automatic localization generation reset formatting. The supported generator
  format option prevents drift; a briefly malformed YAML edit was repaired and
  two generator runs, format and analysis verify the final configuration.

The full VM suite ran once at phase exit. Native SQLite, VM tests and normal
Windows compilation ran serially. CI's desktop baseline now includes the six
new cases; hosted execution is not claimed. Existing physical-printer and
populated-store waivers remain in effect. Phase 5 deliberate cleanup is next.

## Phase 3 closeout — 2026-10-04

The Sales presentation adopts the scoped UI foundation and separates responsive
composition, dialog routing and localized feedback from screen lifecycle/event
forwarding. `sales_screen.dart` now has 346 lines. Search/customer/cart fields
inherit shared focus/error styles; totals and checkout labels wrap safely;
empty product/recent-sale states are explicit, and localized error Retry refreshes
data without resubmitting payments. `SALES_SLICE.md` records the responsibility
map, retained contracts, migration/rollback and evidence reproduction.

No SalesBloc, repository, database or domain implementation changed in this
phase. All 19 captured protected file hashes remain identical. Eight normalized
posted/cancelled database snapshots match for cash, bank, credit and mixed
payments, including every application's table, caches and linked reversal rows.
Normalization removes only fixture clock/generated identifiers, as documented
in `SALES_SLICE.md`; protected monetary/stock assertions remain mandatory.

| Gate | Result | Local evidence under `build/` |
| --- | --- | --- |
| Before-change accounting | Four payment/reversal cases pass | `baseline-phase3-before.log` |
| Focused regression/foundation | 52 cases pass | `baseline-phase3-focused.log` |
| New Sales presentation | Four English/Urdu light/dark loading, empty, error/retry and success cases pass | `baseline-phase3-presentation-final.log` |
| Native Sales | All 20 cases pass in 3m19s after a 43.9-second Windows build | `baseline-phase3-native-final.log` |
| Accounting comparison | Eight snapshot pairs match; 19 protected hashes unchanged | `baseline-phase3-comparison.log` |
| Visual evidence | Two retained before references and sixteen new real-font state captures | `sales-phase3-review/` |
| Formatting | 274 Dart files, zero changes | `baseline-phase3-format.log` |
| Analysis | No issues, 5.3 seconds | `baseline-phase3-analyze-final.log` |
| Phase-end full suite | **549 passed, one optional store-copy check skipped**, 113 seconds | `baseline-phase3-full-suite.log` |
| Normal Windows debug build | Passes in 24.9 seconds; ordinary application executable restored | `baseline-phase3-build.log` |
| Whitespace | Staged and unstaged checks pass | Local `git diff --check` |

The native target covers startup/minimum layouts, payment modes and rejected
payments, cancellation, English/Urdu Tab checkout/navigation/backup/restore,
shortcuts, receipt operations and four light/dark visual scenarios. Its visual
cases also verify search no-results, populated carts, F9, modal theme inheritance
and Escape. The CI baseline aggregator now includes the four new visual cases;
hosted execution has not been claimed.

Failures recorded before closeout:

- The first extraction needed a corrected widget closing structure. The
  analyzer then caught a SizedBox constraint argument, which was replaced by
  ConstrainedBox. Final format/analyzer gates are clean.
- New widget cases exposed grand-total and Urdu checkout-label overflows with
  constrained text metrics. Flexible labels/amounts repair them; all four cases
  and the native layouts pass with unchanged financial values.
- The initial native run passed 18 cases and failed two focus/dismissal
  assertions. The final full affected target passes all 20 with the same
  keyboard expectations; no shortcut or protected behavior was relaxed.
- Initial checkout screenshots captured the shell underneath the modal. The
  corrected capture uses the dialog's overlay boundary; refreshed real-font
  captures were visually inspected.
- Snapshot comparison initially differed only in cancellation clock metadata
  inside notes. The comparison explicitly normalizes that timestamp while
  retaining actor/reason and all financial columns/reversal references.

Full tests ran once at this phase's exit after focused repairs. Native SQLite
targets, VM tests and the normal Windows build ran serially. Phase 0's physical
printer and populated-store waivers remain in effect. Phase 4 starts with the
Products slice; no Phase 4 implementation is included here.

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

The local review snapshot is
`C:/Users/user/.codex/visualizations/2026/10/03/01a10166-8819-7133-9662-f191bd9e0280/formatting-review/`. It contains
`before/`, `after/`, the complete file list, `formatted-files.txt`, and
`formatting-only.patch`. The snapshot was taken after the earlier fixes and
localization generation, so its diff isolates formatting from functional work.
Existing uncommitted changes were preserved. The root Git diff still includes
those earlier changes; it is not itself a formatting-only diff.

Evidence logs: `baseline-urdu-generation.log`, `baseline-format-applied.log`,
and `baseline-format-verified.log`.

The raw snapshot initially lived under `build/`, where the analyzer treated
its copied Dart files as duplicate source. It was moved outside the project.
Formatting also exposed one missing-braces lint in purchase price validation;
adding braces preserves the existing return behavior. The snapshot diff covers
the formatter pass; this one manual lint correction is separate from it.

Final verification: all 433 tests passed (65 seconds), the Windows debug build
passed (50.5 seconds), and the analyzer rerun passed with no issues (92.6 seconds).
Formatting passes for all 228 Dart files. Additional local logs:
`baseline-l10n-format-tests.log`, `baseline-l10n-format-build.log`,
`baseline-l10n-format-analyze-final.log`, and `baseline-format-final.log`.

## 2026-10-03 merge validation and backup creation repair

Ran the requested analyzer before continuing: no issues (92.6 seconds).
A concurrent merge of `origin/master` introduced eight conflicts. Resolved
the conflicts while preserving temporary database fixtures, completed Urdu
translations, and incoming shared UI components. The merged analyzer passed
with no issues (6.7 seconds). The Git merge remains uncommitted.

The incoming invoice invariant suite now uses `useTestDatabase()`, supplies
the required Urdu product name, and seeds matching stock events with
`setTestStock`. Its financial assertions are unchanged. All five cases pass.

Five new backup regression cases run exclusively on temporary databases.
They cover snapshot integrity and original data, committed WAL writes,
distinct successive filenames, invalid retention counts, and recognition/
retention of legacy and manual backup names while preserving unrelated files.
The initial four cases reproduced four failures before the repository repair.

`SettingsRepository` now recognizes both backup naming conventions, generates
microsecond-suffixed manual names, rejects retention counts below one, and
uses SQLite `VACUUM INTO` to produce a standalone snapshot including committed
WAL data. Schema and financial calculations are unchanged. All ten focused
backup/invoice cases pass. The final analyzer passes with no issues
(101.5 seconds), and all 454 tests pass (76 seconds).
The Windows debug build passes (58.9 seconds), all 236 Dart files pass
formatting, and staged/unstaged whitespace checks pass. Build and formatting
logs: `baseline-backup-build.log` and `baseline-backup-format.log`.

Restore is still a separate open defect: `restoreBackup` closes the cached
database connection and does not reopen it. Backup creation coverage does not
prove restore or existing-store upgrades. Manual desktop and copied-store
validation gates remain open.

Evidence logs: `baseline-merge-analyze.log`, `baseline-backup-before.log`,
`baseline-backup-invariants.log`, `baseline-backup-analyze.log`, and
`baseline-backup-suite.log`.

## 2026-10-03 restore connection lifecycle and failure recovery

Completed the next bounded work in two verified steps. First, changed only
the database helper's connection lifecycle: closed cached handles are reopened,
and `close()` clears the cache without opening a new connection. Both lifecycle
regressions failed before this repair and passed afterward. Test teardown now
closes the helper's current connection, including a handle reopened by restore.

Then repaired repository restore behavior. The selected file is checked before
the live database is closed: missing files and the live file itself are rejected;
SQLite integrity, supported version, required tables, and current-version column
names are checked. A standalone staged SQLite snapshot includes source WAL writes
and leaves the selected backup unchanged. An emergency SQLite snapshot captures
the current database, including its WAL, before replacement. Restore reports
success only after the normal database initialization reopens the replacement.
Replacement/upgrade failures copy back the emergency snapshot and reopen it.
Emergency snapshots are retained; temporary staging files are cleaned up.
Overlapping restore calls are rejected across repository instances.

The restore suite covers every table's persisted rows, continued writes after
restore, foreign-key configuration, emergency contents, missing/corrupt/unrelated/
newer/partial/self inputs, a forced version-4 upgrade failure and rollback,
source WAL writes, unchanged source backups, a synthetic version-4 upgrade,
and overlapping restores followed by a successful retry. Seven of the initial
eight restore cases failed against the original repository implementation after
the helper lifecycle repair; only the valid round trip passed.

These are disposable fixtures. The synthetic version-4 case exercises existing
upgrade callbacks but is not an independently captured historical schema or a
real store copy. No production schema, migration callback, ledger calculation,
or live store file was changed. Manual desktop and real-store-copy gates remain
open.

Before the final overlapping-call guard, all 466 tests passed (75 seconds),
analysis passed (79.2 seconds), and the Windows debug build passed (46.7 seconds).
Final verification including the guard: **467 tests passed** (60 seconds),
analysis passed with no issues (13.7 seconds), and Windows debug build passed
(35.7 seconds). All 238 Dart files pass formatting. Staged and unstaged diff
whitespace checks pass. Final logs: `baseline-restore-suite-final.log`,
`baseline-restore-analyze-final.log`, `baseline-restore-build-final.log`, and
`baseline-restore-format-final.log`.

Evidence: `baseline-lifecycle-before.log`, `baseline-lifecycle-after.log`,
`baseline-restore-before.log`, `baseline-restore-after.log`,
`baseline-restore-suite.log`, `baseline-restore-analyze.log`, and
`baseline-restore-build.log`.

## 2026-10-03 historical upgrade and native desktop baseline

Added frozen SQL fixtures for versions 1–4 from the original table/index
definitions at commits recorded in `test/fixtures/database/README.md`.
These fixtures have actual historical columns, rather than a version number
changed on the current schema. Synthetic records include a mixed-payment sale,
a purchase, and populated customer/supplier/stock ledgers. Nine tests exercise
normal database open, restore, previously opened version-1 column state, retained
source backups, every existing row field, identity backfills, integrity, foreign
keys, and repeated open. All nine pass (11 seconds).

Version-1 normal open and restore reproduced a duplicate-column failure:
the original schema already contains `cash_ledger.payment_mode`, while the
upgrade added it unconditionally. The existing migration now checks `_hasColumn`
before executing its unchanged addition. No schema definition, accounting
calculation, or stored financial value was altered.

Added Flutter's SDK `integration_test` development dependency with six new
SDK/transitive entries in the lockfile; existing versions remain unchanged.
The Windows integration harness calls the real app entry point, uses a generated
temporary FFI database path, and mocks preferences and secure storage in memory.
It exercises keyboard PIN login and the sales shell without reading or writing
installed user settings, credentials, lockout state, or store databases.
It closes the database and removes its temporary directory after each scenario.
This does not validate native credential persistence or the full smoke checklist.

Native desktop results: **one passes, two fail**. English startup and keyboard
PIN login pass at 1366×768. The failures remain visible in the integration suite:

| Scenario | Reproduced defect | Next owner |
| --- | --- | --- |
| English at 1024×720 | Product card column overflows by 43 pixels | Presentation repair |
| Urdu sales at 1366×768 | Product card overflows by 3.8 pixels, app header by 8 pixels, empty cart by 7 pixels | Presentation repair |

The relevant widgets are `product_card.dart:43`, `app_header.dart:127`, and
`sales_cart_panel.dart:170`. The Urdu direction assertion passes before the
layout-error assertion fails. These are baseline blockers; no production UI
changes were mixed into the database migration repair. The full desktop gate,
real-store-copy checks and CI gate remain open.

All **476 tests under `test/` pass** (79 seconds). Native integration scenarios
are run separately with
`flutter test integration_test/desktop_startup_test.dart -d windows --no-pub`;
their failing result is not included in that 476-test success count.
All 240 Dart files under `lib/`, `test/` and `integration_test/` pass formatting.
Final analysis passes with no issues (10.6 seconds), the ordinary Windows debug
build passes (28.7 seconds), and staged/unstaged whitespace checks pass.
Logs: `baseline-historical-analyze-final.log` and
`baseline-historical-build.log`.

Logs: `baseline-historical-before.log`, `baseline-historical-after.log`,
`baseline-historical-suite.log`, `baseline-historical-format.log`,
`baseline-desktop-dependencies.log`, and `baseline-desktop-startup.log`.

## 2026-10-03 native desktop layout repair

This continuation changes presentation only: `sales_product_panel.dart`,
`sales_cart_panel.dart` and `app_header.dart`. Product selection, customer,
checkout and discount callbacks are preserved; no repository, financial,
stock or schema changes are part of this repair.

The product grid now uses its available width, padding and spacing to choose
one to eight columns instead of forcing four columns into narrow panels.
Card height retains the existing aspect ratio when it fits, with a minimum
derived from the active font and text scale for price and two name lines.
The header treats 56 pixels as a minimum, allowing the Urdu clock to determine
its needed height. Empty-cart content can scroll, and the decorative icon
shrinks or disappears when necessary to keep the localized message visible.

The Windows harness retains the original three checks and adds Urdu at
1024×720. Each scenario checks keyboard PIN login, the sales shell, temporary
database isolation, correct text direction, absence of rendering errors and
visibility of the empty-cart message. It also captures the rendered route as
a PNG for visual review. The screenshots use fresh synthetic sample data.

Visual review confirmed that the cards and header fit. An intermediate Urdu
minimum-size screenshot showed the decorative cart icon pushing the message
below the viewport; the responsive icon refinement corrected this before the
final verification.

A parallel desktop-build/VM-test attempt hit Windows locking on the shared
generated SQLite DLL. Final desktop, VM-suite and build checks are run serially;
the failed VM log is retained as
`baseline-desktop-layout-concurrent-failure.log`.

Final serial Windows integration run: all **four scenarios pass** (10 seconds;
integration build 40.3 seconds), including the empty-message visibility assertion.
Screenshots are retained outside the build directory at
`C:/Users/user/.codex/visualizations/2026/10/03/01a10166-8819-7133-9662-f191bd9e0280/desktop-layout-review/`.
The four PNG names match the integration scenario names. English and Urdu
minimum-size images were inspected; the empty message is visible and the cards
and header fit. Captures show the client area inside the requested outer window.
Log: `baseline-desktop-layout-final.log`.

This completes the identified layout repair, not the complete desktop workflow
checklist or real-store-copy validation. Those Phase 0 gates remain open.

Final serial verification: **476 tests pass** (65 seconds), ordinary Windows
debug build passes (23.1 seconds), analysis has no issues (8.5 seconds), all
240 Dart files pass formatting, and staged/unstaged whitespace checks pass.
The ordinary application executable is the final build output. Serial run
instructions and isolation limits are recorded in `integration_test/README.md`.
Logs: `baseline-desktop-layout-suite-final.log`,
`baseline-desktop-layout-build-final.log`,
`baseline-desktop-layout-analyze-final.log`, and
`baseline-desktop-layout-format.log`.

## 2026-10-03 desktop workflows and existing-copy diagnosis

This continuation adds disposable Windows workflow tests and an optional
existing-copy validation tool. The only new production change is presentation:
each customer suggestion ListTile receives its own transparent Material ancestor.
The native test reproduced Flutter's assertion that the surrounding decorated
background hides tile ink effects. No checkout, repository, stock, ledger or
schema behavior was changed in this continuation.

All **five native workflow scenarios pass** (40 seconds; build 41.5 seconds):

- Five invalid PIN attempts cause lockout; invalid recovery is rejected;
  valid recovery replaces the PIN and rotates the recovery code. Logout and
  re-login succeed, and the old PIN/recovery code are rejected.
- Cash, bank, credit and mixed payments save a selected customer's sale and
  update persisted invoice totals, stock, cash and customer balances.
- Each sale is cancelled through the UI. Stock and balances return to their
  starting values, cash inflows/outflows net to zero, and the cancelled-sale
  menu removes the cancellation action. Reopening that menu leaves stock events
  unchanged. Invalid initial payment fields keep Save disabled and invoices empty.

Customer search is debounced by 300 milliseconds. The harness now explicitly
waits for the matching suggestion instead of assuming pumpAndSettle waits for
timers. An F9 attempt after customer selection did not open checkout; these
passing workflows use the checkout button. Keyboard navigation remains an open
presentation investigation, not a claimed passing check. Authentication uses
memory preferences/secure storage, so native credential persistence is untested.

Logs retain intermediate failures: `baseline-desktop-workflows.log`,
`baseline-desktop-workflows-material.log`. Final workflow evidence:
`baseline-desktop-workflows-checkout.log`.

`capture_store_copy.py` captured the existing default workspace database via a
read-only SQLite connection using the backup API, including committed WAL data.
It is version 5, passes integrity checking, and contains one product, customer
and supplier but **no invoices, purchases or ledger events**. Its provenance is
unconfirmed; it is not evidence of a populated real-store upgrade.

The optional `STORE_COPY_PATH` test opens a temporary duplicate through normal
app initialization, verifies foreign keys and existing rows, diagnoses balance
consistency, then checks backup/restore and all post-open rows. The captured
file's SHA-256 remains unchanged. **One optional copy-validation test passes**;
log: `baseline-existing-store-validation.log`.

| Finding | Severity / owner | Outcome |
| --- | --- | --- |
| Customer dropdown background hides ListTile effects | P2 / presentation | Reproduced and repaired; native workflow checks pass |
| One existing product stock cache lacks matching stock events | P2 / database baseline audit | Diagnosed only; source untouched |
| One existing customer balance lacks matching ledger events | P2 / accounting baseline audit | Diagnosed only; source untouched |
| F9 did not open checkout after customer selection in the harness | P2 / presentation investigation | Full keyboard gate remains open |

Private snapshot, manifest and count-only diagnosis are retained outside build:
`C:/Users/user/.codex/visualizations/2026/10/03/01a10166-8819-7133-9662-f191bd9e0280/store-copy-review/`.
The snapshot is `existing_store_20261003_175926_908504.db` with SHA-256
`8e2a146e119d379493a2ccbcebbac29ad5fcc7350b5fa0fc17a5708c8b44dab0`.

Phase 0 remains open for full desktop CRUD/purchase/payment/stock/cash workflows,
printing/PDF and keyboard navigation, a populated store copy with confirmed
provenance, final failure ownership review and CI after those gates are green.

Final serial verification: **476 tests pass, one optional copy test skipped**
(68 seconds). The supplied-copy run separately passes its one test. Analysis
has no issues (9.8 seconds), the ordinary Windows debug build passes (23.4
seconds), all 243 Dart files pass formatting, and staged/unstaged whitespace
checks pass. The ordinary app executable is the final build output.
Logs: `baseline-workflows-suite.log`, `baseline-workflows-analyze.log`,
`baseline-workflows-build.log`, and `baseline-workflows-format.log`.

## 2026-10-03 sales keyboard focus repair

Initial analyzer check passes with no issues (5.3 seconds). A native probe
confirms F9 works after selecting a product alone, but fails after customer
selection followed by product selection. Focus diagnostics show the route's
modal FocusScope is primary, outside the sales shortcut subtree.

The production repair is presentation only: SalesScreen's existing autofocus
Focus wrapper becomes a FocusScope. When a text field or removed suggestion
loses focus, the sales scope retains keyboard dispatch under the sales shortcuts.
No shortcut mapping, callback, transaction, repository or schema is changed.
An intermediate attempt to focus item search after customer selection did not
survive the next product click; it was removed before final validation.

Both native keyboard scenarios pass (11 seconds; build 39.2 seconds). They
cover F9 with and without selected customer, Escape dismissal of checkout and
clear-cart dialogs, Ctrl+F focus, Ctrl+N customer entry and Ctrl+Shift+N new sale.
F9 on an empty cart opens no checkout. Invoices remain empty, stock remains 45
and dismissing customer entry adds no customer. These are partial keyboard
checks; full Tab/Shift+Tab navigation, other screens and Urdu remain open.

Evidence logs: `baseline-keyboard-diagnosis.log` (product-only pass),
`baseline-keyboard-customer-before.log` (reproduced failure/focus diagnostics),
`baseline-keyboard-after.log` (intermediate attempt) and
`baseline-keyboard-scope.log` (both passing final keyboard scenarios).

The five prior workflow scenarios pass again through F9, with additional
named-customer overpayment rejection before valid cash/bank/credit/mixed saves
and cancellations. A separate walk-in scenario passes: Rs 179 cannot save a
Rs 180 sale; Rs 181 shows Rs 1 change and saves only Rs 180 as cash inflow.
Walk-in checkout omits credit entry, and existing customer rows/ledger remain
unchanged. No production financial behavior was changed to make these pass.

The workflow expansion initially assumed a disabled walk-in credit field and
a zero sample-customer balance. The actual UI omits credit entry and the
sample has a populated opening balance. Test expectations now capture and
compare existing rows rather than rewrite these baseline values.
Logs: `baseline-keyboard-payment-workflows.log` (five pass plus new fixture
assumption failure), `baseline-keyboard-walk-in-final.log` (balance assumption)
and `baseline-keyboard-walk-in-verified.log` (walk-in passes; 6 seconds,
build 39.5 seconds). All six workflow scenarios have passing evidence across
these runs; the two keyboard scenarios are separate from this count.

Final serial verification: **476 regression tests pass, one optional store-copy
test skipped** (67 seconds); analysis has no issues (7.1 seconds), the ordinary
Windows debug build passes (23.2 seconds), all 244 Dart files pass formatting,
and staged/unstaged whitespace checks pass. The ordinary app executable is the
final build output. Logs: `baseline-keyboard-suite-final.log`,
`baseline-keyboard-analyze-final.log`, `baseline-keyboard-build-final.log` and
`baseline-keyboard-format.log`.

## 2026-10-04 desktop navigation, purchase and supplier payment

This continuation adds `desktop_purchase_test.dart`. The only new production
change is presentation: the stock DataTable can scroll horizontally inside its
existing vertical viewport. Natural column widths prevent the reproduced
15-pixel header overflow. Sorting, selection, actions and financial callbacks
are unchanged. No repository, schema, stock or ledger calculation was edited.

The initial native run reproduced the stock-table overflow and a missed purchase
Save tap while the earlier validation snackbar covered the button. The harness
now waits for that snackbar to clear and treats missed taps as fatal. The first
three-scenario run then passed; supplier-payment coverage was added afterwards.

The interrupted supplier-payment run had no final result. After resuming under
restricted workspace permissions, Flutter's SDK cache lock outside the workspace
prevented startup. The blocked wrapper was cancelled and the tests were rerun
with approved SDK-cache access. Final native evidence: **all three scenarios
pass** (33 seconds; Windows integration build 75.9 seconds):

- English and Urdu sidebar navigation visits stock, accounts, settings,
  purchases and sales; both customer/supplier account tabs render. Direction
  and requested locale are checked; navigation creates no invoices/purchases.
- Missing supplier and zero purchase quantity cannot save a purchase. Two
  units at Rs 150 save one purchase, increasing sample stock from 45 to 47
  and supplier liability by Rs 300; purchase creation adds no cash entry.
- Through Accounts, a zero supplier payment creates no payment/cash rows.
  Rs 100 payment saves once, reduces supplier liability by Rs 100, records
  supplier credit and an Rs 100 cash outflow, and leaves stock/purchase intact.

The transaction workflow is tested in English. Urdu payment dialogs, purchase
cancellation, customer payment, CRUD, stock adjustments, full keyboard traversal
and print/export remain open. Preferences and credentials remain memory-backed;
all database writes use generated temporary databases.

| Finding | Severity / owner | Outcome |
| --- | --- | --- |
| Stock-table header overflow | P2 / presentation | Reproduced and repaired; both language navigation checks pass |
| Purchase Save obscured by validation snackbar in the harness | Test infrastructure | Wait for the snackbar; missed taps are fatal |
| Missing-supplier error is unmapped in ErrorHandler | P2 / localized error mapping | Recorded; validation blocks persistence, localization remains to review |
| Supplier payment header/action use English literals | P2 / localization review | Recorded; Urdu transaction flow is not claimed as verified |

Logs: `baseline-purchase-desktop-before.log`,
`baseline-purchase-desktop-layout.log`, `baseline-purchase-payment-desktop.log`
(interrupted), and `baseline-purchase-desktop-resumed.log` (all three pass).
Run instructions and remaining limits are in `integration_test/README.md`.

Final verification: **476 regression tests pass, one optional store-copy test
skipped** (76 seconds). Analysis has no issues (65.2 seconds), the ordinary
Windows debug build passes (53.5 seconds), all 245 Dart files pass formatting,
and staged/unstaged whitespace checks pass. No unresolved Git paths are present;
the existing merge and working-tree changes remain uncommitted. The final
executable is the ordinary application, not the integration harness.
Logs: `baseline-navigation-suite-final.log`, `baseline-navigation-analyze-final.log`,
`baseline-navigation-build-final.log` and `baseline-navigation-format.log`.

## 2026-10-04 customer receipts and purchase cancellation

This continuation changes two presentation widgets only. Recent stock activities
can scroll horizontally without compressing table headers; activity details,
header and actions share one vertical list so the short side panel can scroll.
The native harness reproduced 8.8-pixel table and 12-pixel panel overflows before
these repairs. No protected accounting, stock, cancellation or schema logic was
changed.

Three desktop scenarios have passing evidence across the final runs:

- English and Urdu customer receipt flows reject zero without adding receipt,
  cash or ledger rows. Rs 100 against a Rs 300 opening balance saves one receipt,
  records a Rs 100 customer credit and cash inflow, leaves Rs 200 outstanding
  and preserves stock. The Urdu customer row is reached by scrolling the list.
- A repository-created purchase is cancelled through stock activity history.
  Declining confirmation preserves completed status and stock 47. Confirmation
  changes status to cancelled, returns stock to 45 and supplier balance to its
  starting value, and adds exactly one stock reversal. A repeat UI request after
  the rapid-request window adds no stock or supplier-ledger reversal.

Customer checks pass in `baseline-accounts-stock-scroll.log`; the final focused
cancellation passes in `baseline-stock-cancellation-final.log` (13 seconds;
build 37.2 seconds). Intermediate evidence includes
`baseline-accounts-stock-before.log` (fixture constructor mismatch),
`baseline-accounts-stock-run.log` (first accounting/layout findings) and
`baseline-accounts-stock-layout.log` (panel overflow and lazy row lookup).
Details/actions are lazily built in the scrolling panel, so tests scroll to the
action before tapping and retain fatal missed-tap checks.

### Open P1 accounting defect: mixed customer-ledger timestamps

The initial desktop overpayment sequence exposed a real financial failure:
Rs 300 opening balance followed by receipts of Rs 100 and Rs 250 should leave
Rs -50, but cached and last-entry balances become Rs +50. The opt-in isolated
regression confirms the same result with a UTC opening entry at 05:00 and local
receipt strings at 10:01/10:02 on the same date (Asia/Karachi).

Opening entries use UTC ISO timestamps containing `T`; the receipt dialog uses
local `yyyy-MM-dd HH:mm:ss` strings. `CustomersRepository.addPayment` selects
the previous balance with textual `ORDER BY transaction_date DESC, id DESC`.
On the same date, `T` sorts after the space, so it can select the opening entry
again instead of the earlier receipt. The second receipt starts from Rs 300,
producing Rs 50 instead of subtracting it from the correct Rs 200.

`test/integration/customer_payment_date_order_test.dart` retains the correct
negative-balance expectation. Running with
`--dart-define=RUN_LEDGER_DATE_REGRESSION=true` currently **fails: expected -5000,
actual +5000 paisa**. Log: `baseline-customer-date-order-reproduction.log`.
The default suite explicitly skips this known failure pending accounting review;
it must not be interpreted as financial baseline completion.

The repository guardrails state that AI must not modify ledger balance logic;
the fix must be a separate accounting-reviewed change. Existing-store data and
financial implementation remain untouched in this continuation.

| Finding | Severity / owner | Outcome |
| --- | --- | --- |
| Repeated customer receipt selects stale balance across mixed date formats | P1 / accounting review | Confirmed by native flow and opt-in failing regression; unresolved Phase 0 gate |
| Recent-activity table/panel overflows | P2 / presentation | Repaired and verified on native Windows |
| Cancelled activity details retain the old cancel action until reopened | P2 / presentation/state refresh | Repeat request cannot add a reversal; stale detail presentation remains to review |

Customer overpayment is not claimed as passing. CRUD, stock adjustment, printing,
full keyboard navigation and populated store-copy gates also remain open.

Final verification: **476 tests pass, two explicitly skipped** (67 seconds).
The skips are the optional existing-store copy and the known failing mixed-date
accounting regression above. Analysis has no issues (7.8 seconds), the ordinary
Windows debug build passes (21.9 seconds), all 247 Dart files pass formatting,
and staged/unstaged whitespace checks pass. The final executable is the ordinary
app. Phase 0 remains blocked on the P1 financial finding despite these checks.
Logs: `baseline-accounts-stock-suite-final.log`,
`baseline-accounts-stock-analyze-final.log`, `baseline-accounts-stock-build-final.log`
and `baseline-accounts-stock-format.log`.

### 2026-10-04 ledger append-order repair and remaining desktop checks

This section supersedes the unresolved P1 and stale-detail outcomes above.
The user explicitly authorized resolving bugs discovered during tests without
separate correction approval, including the ledger regression.

The six current-balance reads in customer, invoice, supplier and purchase
repositories now select the most recently appended ledger ID. Text date ordering
could select an older opening balance when local space-separated timestamps and
UTC ISO timestamps were mixed; it also mishandled backdated financial events.
Display/history ordering is unchanged. This fixes future operations without a
schema migration or rewriting existing-store rows.

The receipt regression is now mandatory. Three repository cases pass, covering
the original Rs 300 minus Rs 100 minus Rs 250 failure, another backdated receipt,
credit sale/payment/cancellation after a future-dated opening, and supplier
purchase/payment/purchase/reversal after a future-dated event. Assertions compare
cached balances, appended running balances, signed ledger totals, cash and stock.
Two initial failures in the new sale fixture were missing `total` and
`name_english` fields; these fixture errors were corrected before the passing run.
Evidence: `baseline-ledger-order-focused.log`.

A separately scoped presentation fix closes the stock detail panel after a
successful action. Reopening the original cancelled purchase reads its refreshed
status and offers no cancellation action. A repeated repository cancellation is
rejected without adding stock or supplier reversal rows. The first native run
passes all three receipt/cancellation cases (`baseline-ledger-order-desktop.log`),
including repeated receipts and correct Rs -50 overpayment in English and Urdu.

The accounts/stock native target is extended for the remaining English/Urdu stock
adjustment and cash-ledger workflows: invalid stock input leaves events unchanged,
stock 45 → 50 → 43 persists +5/-7 events, zero cash input leaves no rows, and
Rs 100.25 cash in minus Rs 20.10 cash out yields exactly 8015 paisa. Customer and
supplier rows, sales and purchases are checked for unintended changes.

The initial cash selector omitted the displayed colon and was corrected in the
test. English then passed, while Urdu reproduced a **27-pixel vertical overflow**
in `CashLedgerListTile`: its two amount labels exceeded `ListTile`'s fixed
48-pixel trailing area. The row now uses a padded, intrinsically sized layout so
Urdu text determines its height. Amount formatting and persisted values remain
unchanged. Reproduction: `baseline-stock-cash-desktop-final.log`.
All **five** combined native Windows cases now pass (88 seconds after a
37.3-second build), including reopening the original cancelled purchase and
English/Urdu stock and cash workflows. Evidence:
`baseline-stock-cash-desktop-repaired.log`.

Existing stores with previously incorrect balances still require diagnosis on
a verified populated backup; this change does not silently repair historical
data. CRUD/archive, print/export, full keyboard traversal, the populated
real-store upgrade gate and CI remain in Phase 0's remaining work.

Final regression verification: **479 tests pass, one optional existing-store-copy
test skipped** (72 seconds). The mixed-date financial test is no longer skipped.
Analysis has no issues (8.7 seconds), all 248 Dart files pass formatting, and
staged/unstaged whitespace checks pass. Evidence:
`baseline-ledger-order-suite-final.log`, `baseline-ledger-order-analyze-final.log`
and `baseline-ledger-order-format-final.log`.
The ordinary Windows debug build succeeds (31.6 seconds), restoring the app
executable after native test harness builds. Evidence:
`baseline-ledger-order-build-final.log`.

### 2026-10-04 account CRUD and archive continuation

The user requested focused tests during steps and the full suite only at each
phase's end. The previous 479-test full run remains historical evidence; this
continuation does not claim another full-suite run.

Six focused regressions reproduced supplier/account defects before correction:
supplier nonzero opening balances had no ledger entry; ordinary detail edits
could overwrite balances changed by a payment; duplicate supplier IDs could
replace existing records; and opening ledger writes were not atomic with supplier
creation. Evidence: `baseline-account-crud-reproduction.log`.

Supplier creation now inserts a signed opening adjustment in the same transaction,
with duplicate IDs rejected. Zero opening balances add no financial event.
Ordinary customer/supplier updates preserve the financial balance cache, and the
supplier edit form makes that balance read-only. New store rows are covered;
existing store balances are not rewritten. The six new cases plus customer
opening, ledger append-order and customer-controller tests pass: **78 focused
tests**, six seconds (`baseline-account-crud-focused.log`).

The native target `integration_test/desktop_account_crud_test.dart` checks empty
form rejection, required fields, precise credit/opening amounts, address editing,
archive and restore for both account types in English and Urdu. It compares
ledger rows across metadata/archive operations and checks that cash, payments,
sales, purchases and stock are unaffected. A test compile error used a
`TextFormField.readOnly` getter; the assertion now inspects its inner `TextField`.
Supplier add/archive headings are localized and archived names follow the active
language. Product CRUD remains the next desktop checklist item.

Both native account scenarios pass (49 seconds):
`baseline-account-crud-desktop-final.log`. The first native run reached supplier
editing but its test selector expected Save rather than Update; the selector was
corrected before the passing run. Final analysis has no issues (9.6 seconds), all
250 Dart files pass formatting, and staged/unstaged whitespace checks pass.
Evidence: `baseline-account-crud-analyze-final.log` and
`baseline-account-crud-format-final.log`. No full suite was run for this step.
The ordinary Windows debug build passes (26.1 seconds), replacing the test
harness executable: `baseline-account-crud-build.log`.

### 2026-10-04 product catalog and CRUD continuation

Catalog inspection found no visible entry point and a load-more implementation
that repeatedly fetched/appended the entire first result set. The stock toolbar
now opens Items. A separate catalog query pages active products in stable
name/ID order; management paging no longer modifies sales search or barcode
caches. Search resets its offset and stale load results are ignored.

The item form rejects whitespace-only English names, trims both names, and lets
an existing brand be cleared. Native testing reproduced another metadata defect:
an edit changed the creation timestamp from SQLite's original space-separated
string to an ISO string. Product edits now preserve the stored timestamp exactly.
The original assertion is retained. Evidence: `baseline-product-desktop.log`.

Six focused checks pass (seven seconds), covering real distinct catalog pages,
search reset, archived filtering, English/code/Urdu search, creation timestamp
and stock preservation, and existing item toolbar/table contracts:
`baseline-product-focused-final.log`. The initial widget fixture needed database
seeding outside the fake clock and a required Urdu name; those fixture errors
were corrected. No full suite was run for this incremental step.

The native target exercises create/edit/archive in both languages through the
visible navigation entry. Archive decline preserves the active record; confirm
sets `is_active = 0` while retaining stock, prices, creation time, stock events and
customer/supplier/cash/invoice/purchase history. New product creation does not
invent financial or stock events. Product restore has no UI and is not claimed.
The next native run passed timestamp preservation but its final name-absence
assertion also matched the search input. The assertion is now scoped to the
catalog table (`baseline-product-desktop-final.log` records that test-only
failure). Financial and historical preservation assertions were not weakened.

Final verification: **six focused tests and both native product scenarios pass**.
Native runtime is 67 seconds after a 39.7-second build; evidence:
`baseline-product-desktop-passing.log`. Analysis has no issues (10.7 seconds),
all 253 Dart files pass formatting and staged/unstaged whitespace checks pass.
Evidence: `baseline-product-analyze-final.log`, `baseline-product-format-final.log`.
This closes the disposable-desktop create/edit/archive checklist for products,
customers and suppliers. Remaining Phase 0 work is print/export, full keyboard
traversal, verified populated-store upgrade/diagnosis and the final baseline/CI
gates. No full test suite was run in this continuation.
The ordinary Windows debug build passes (22.4 seconds), restoring the app
executable after the native test harness: `baseline-product-build.log`.

### Receipt print/export continuation — 2026-10-04

Receipt generation now uses saved shop/customer/item names, the app language,
paper width (58mm/80mm/A4), font size and address/phone/date/customer/payment
visibility preferences. Invoice payment amounts come from saved notes. All
amounts retain paisas; loaded invoice quantities retain fractional units rather
than truncating them. Rendering and export do not change the financial schema.
Export filenames sanitize separators and invalid Windows characters. Payment
receipt export no longer updates the nonexistent `receipt_pdf_path` column.

Printing returns the platform's acceptance/cancellation result. Cancelled print
dialogs do not show success or trigger tracking/refresh. The sales screen and
post-sale dialog no longer dispatch a second print event after directly printing.
The event handler remains available and also handles cancellation. Print requests
use the configured paper format and disable dynamic relayout of prebuilt bytes.

The initial Urdu PDF failed in the PDF library's bundled-font subset writer.
Arabic text now uses Flutter's OpenType/Nastaleeq renderer and embeds the result
as a 216-dpi image; Latin text and monetary values remain selectable. Urdu text
is therefore visually readable but not searchable/selectable in exported PDFs.
Synthetic English/Urdu invoices, a Rs 123.45 payment receipt and a 70-item 58mm
invoice were rasterized and visually inspected. The long invoice spans four
pages, retains item 70 and ends with Rs 10,552.50. Evidence is under
`build/receipt-review/`; these are synthetic QA documents, not store receipts.

Eight focused tests pass in four seconds, including real fractional invoice
loading and the existing accounting/rollback/cancellation invariants:
`baseline-receipt-focused.log`. Both English/Urdu native post-sale scenarios pass
(eight seconds after a 47.2-second build): `baseline-receipt-desktop.log`.
The native tests use a fake printing backend, inspect one request per click,
verify cancellation and save buttons, and compare invoice/item/receipt/product/
customer/stock/customer-ledger/supplier-ledger/cash-ledger rows before and after.
No physical print jobs are issued. Hardware-printer verification remains open.

Analysis has no issues (11.7 seconds): `baseline-receipt-analyze.log`. No full
suite was run; it remains reserved for the phase-end gate. Keyboard/minimum-window
checks, a verified populated-store diagnosis/upgrade, physical printing and the
final baseline/CI gates remain. The existing logo/printer-selection settings and
stock/ledger export placeholders are not claimed as implemented by this step.
All 257 Dart files pass formatting; staged and unstaged whitespace checks pass.
The ordinary Windows debug build passes (24.5 seconds), restoring the normal app
after the native harness: `baseline-receipt-build.log`.

### Phase 0 closeout — 2026-10-04

The user requested skipping physical-printer verification and verified populated
real-store diagnosis/upgrade, then completing Phase 0 in one go. Both are recorded
as waived checks, not passes. The optional `STORE_COPY_PATH` test remains skipped;
synthetic historical upgrades and temporary-database restore checks remain covered.
No real-store rows were modified and no physical print jobs were issued.

Final checks use Flutter **3.44.4** and Dart **3.12.2**:

| Gate | Recorded outcome | Evidence |
| --- | --- | --- |
| Locked dependencies | `flutter pub get --enforce-lockfile` passes; no upgrades | `baseline-phase0-dependencies.log` |
| Localization | `flutter gen-l10n` passes; generated Dart hashes unchanged | `baseline-phase0-localization.log` |
| Formatting | 259 Dart files checked, zero changes | `baseline-phase0-format-verified.log` |
| Analysis | No issues, 8.4 seconds | `baseline-phase0-analyze-verified.log` |
| Full suite | 494 passed, one optional store-copy check skipped, 90 seconds | `baseline-phase0-full-suite.log` |
| Native desktop | 28 distinct scenarios verified across the runs described below | `baseline-phase0-desktop-gate.log`, `baseline-phase0-keyboard-verified.log` |
| Ordinary Windows debug build | Passes in 23 seconds; restores the app executable after the harness | `baseline-phase0-build.log` |
| Staged/unstaged whitespace | Both `git diff --check` checks pass | Local exit-code checks |
| CI | Windows workflow structure validated; hosted execution pending push/PR | `.github/workflows/flutter-baseline.yml` |

`integration_test/desktop_baseline_test.dart` registers the eight native targets
as one 28-scenario entry point. Its aggregate run passed 26 scenarios in 6 minutes
31 seconds after a 39.4-second build. The remaining two completed their keyboard
flows but failed the fixture's final foreign-key assertion because restore had
closed the fixture's cached database handle. The fixture now reacquires the open
handle and checks both its disposable path and `PRAGMA foreign_key_check`.
The affected keyboard target was rerun: **all four scenarios pass** in 2 minutes
3 seconds after a 39.2-second build. Two are the newly added complete keyboard
flows; two are shortcut cases already passed in the aggregate. Thus all 28
distinct scenarios have passing evidence; the aggregate command itself is not
claimed as a single green run. Financial assertions were retained. Only the
affected target was rerun after this fixture-only repair, following the user's
time constraint; the full suite ran once at the phase exit.

The two new keyboard scenarios run in English and Urdu at **1024×720**. They
cover PIN login, product/customer selection, price/quantity/discount focus,
checkout/payment/save, post-sale buttons, sidebar navigation, account tabs,
settings, visible backup creation/restoration, KPI refresh and logout without
mouse taps. Restore compares every non-internal SQLite table's rows against the
pre-backup snapshot. The fixture restores the native window size at teardown.
Current screenshots are `build/desktop-keyboard-review/en-minimum.png` and
`build/desktop-keyboard-review/ur-minimum.png`.

Reproduced defects were fixed before closeout:

| Failure | Repair and verification |
| --- | --- |
| Keyboard focus did not enter the post-sale dialog | Autofocus its print button; complete keyboard flows pass |
| Sales Tab traversal could not reach the sidebar | Use parent-scope traversal at the sales focus boundary; keyboard navigation passes |
| Urdu customer selection/totals overflow at minimum height | Bound dropdown/footer height and scroll totals; minimum-window checkout passes |
| Stock heading, empty purchase cart and shared loading state overflow | Allow vertical scrolling in constrained panes; native checks and small-pane regression pass |
| Urdu settings tiles overflow at minimum width | Choose two or three grid columns from available width; native navigation passes |
| Supplier-required validation lacked a localized mapping | Map the reproduced message to `selectSupplier`; English/Urdu regressions pass |
| Receipt shop details read legacy keys rather than current schema keys | Read saved `shop_name_english`, `shop_name_urdu`, `shop_address` and `contact_primary`, retaining legacy fallbacks; export tests pass |
| Restore teardown used a closed fixture handle | Reacquire the connection; preserve path and foreign-key assertions; all four keyboard tests pass |

The closeout repairs do not change the schema or financial persistence rules.
Previously recorded accounting repairs retain their regression expectations.
The KPI snapshot's existing 90-second cache/manual-refresh contract is retained;
keyboard refresh verifies the saved invoice after restore.

The Windows CI workflow pins Flutter 3.44.4 and runs locked dependency resolution,
localization drift detection, formatting, analysis, the full suite, the exact
desktop aggregate target and a normal debug build, serially. Workflow YAML was
parsed and its Windows target, SDK pin and ten steps checked locally. No hosted
GitHub Actions result is claimed. Reproduce the principal local gates with:

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --no-pub
flutter test --no-pub
flutter test integration_test/desktop_baseline_test.dart -d windows --no-pub
flutter build windows --debug --no-pub
```

Known deferred limitations have explicit ownership:

| Limitation | Severity / owner | Disposition |
| --- | --- | --- |
| Physical printer compatibility | P2 / desktop printing validation | Waived by user for Phase 0 |
| Verified populated-store provenance, diagnosis and upgrade | P1 / existing-store validation | Waived; earlier empty-copy cache/ledger mismatches remain recorded, source unchanged |
| Supplier payment heading still uses English | P2 / Accounts presentation, Phase 4 | Financial validation passes; complete Urdu localization is not claimed |
| Logo/printer selection, USB/offsite backup and stock/ledger export placeholders | P2 / feature owners, Phase 4 | Outside this receipt PDF and local backup baseline |
| Urdu PDF text is rendered as images | P2 / receipt presentation | Visually reviewed; Urdu PDF search/select remains unsupported |

Phase 0 has no remaining work within the amended scope. Phase 1 is next; it has
not been started by this closeout.

### Phase 1 closeout — 2026-10-04

The user requested completing Phase 1 in one go without approval pauses. The
phase adds **28 regression cases**: 26 real SQLite workflow tests in
`test/integration/protected_workflows_test.dart` and two money round-trip/display
tests in `test/unit/money_test.dart`. `PHASE_1_REGRESSION_HARNESS.md` maps every
required workflow to named tests and its persisted expectations, including the
existing mandatory backup, restore and historical upgrade suites.

New coverage asserts four payment modes at exact paisa precision, saved discount
totals, linked original/reversal IDs, complete row preservation after invalid
payments or math, competing checkouts against limited stock, concurrent duplicate
cancellation, multi-item rollback, consumed-stock purchase return rejection,
customer CASH/BANK receipts and supplier payment preservation after return.
Fixture-only triggers force failures in final ledger writes for sales, purchases,
both payment types and reversals. Each failed transaction preserves all table
rows; failed reversals succeed on retry after the fault is removed. Expected
injected exceptions are test stimuli, not unresolved product failures.

All tests use the existing isolated temporary-database harness; transaction races
exercise the current single-process connection. No production code, financial
rule or schema changed during Phase 1. No new product defect was reproduced.
Existing Phase 0 source changes and staged work are preserved.

| Gate | Result | Evidence |
| --- | --- | --- |
| Final focused run | 35 passed in four seconds (28 new plus seven existing money cases) | `baseline-phase1-focused-final.log` |
| Formatting | 260 Dart files checked, zero changes, 0.85 seconds | `baseline-phase1-format.log` |
| Analysis | No issues, 6.9 seconds | `baseline-phase1-analyze.log` |
| Phase-end full suite | **522 passed, one skipped**, 93 seconds | `baseline-phase1-full-suite.log` |
| Whitespace | Staged/unstaged checks pass | Local `git diff --check` checks |

The full suite ran once at phase end, after focused checks. The single skip is
the same optional `STORE_COPY_PATH` check covered by the user's Phase 0 waiver.
Windows CI's existing full-suite step discovers the new harness automatically;
hosted CI has not been executed locally. Desktop/build checks were not repeated
for test/documentation-only changes; Phase 0's native evidence and restored
ordinary Windows executable remain applicable. Phase 1 exit criteria are met;
Phase 2 is next and was not started in this continuation.

### Phase 2 closeout — 2026-10-04

The user requested completing Phase 2 in one go. `UI_SYSTEM.md` records the
component inventory, semantic token/color/typography roles, control states,
desktop sizing, keyboard contracts, migration boundaries and repeatable checks.
`AppUiTheme` is an opt-in scoped presentation foundation with tested Material
color pairs, compact English/Urdu metrics, minimum-height controls, focus borders,
hover/pressed overlays, disabled styling and growing table rows. Existing global
theme callers remain available for explicit feature migration in Phases 3/4.

`AppActionButton` provides primary/secondary/destructive and disabled/busy states;
`AppFormDialog` provides scrollable content and fixed token-based LTR/RTL width
ranges; `AppDataTable` provides independent vertical/horizontal scrolling. The
gallery combines these with existing search and loading/empty/error components,
localized form validation, table selection, modal actions and Retry. It is a
separate development entry point with no store database, credentials, persisted
settings or printing. Production startup minimum dimensions and the settings
grid now call `AppLayout` with identical values to the preceding phase. No
repositories, BLoCs, financial rules or database schema changed.

| Gate | Result | Evidence |
| --- | --- | --- |
| Focused checks | 23 pass in six seconds: 12 theme variants, layout boundaries and ten widget cases | `baseline-phase2-focused-final.log` |
| Native gallery | All four English/Urdu light/dark cases pass in 13 seconds after a 52.2-second build | `baseline-phase2-native-verified.log` |
| Visual references | Twelve real-font controls/feedback/dialog PNGs; RTL and light/dark rendering inspected | `build/ui-gallery-review/` |
| Formatting | 268 Dart files including `tool/`; zero changes, 2.97 seconds | `baseline-phase2-format.log` |
| Analysis | No issues, 36.4 seconds | `baseline-phase2-analyze-verified.log` |
| Phase-end full suite | **545 passed, one skipped**, 107 seconds | `baseline-phase2-full-suite-verified.log` |
| Normal Windows build | Passes in 55.3 seconds; ordinary app executable restored after the native harness | `baseline-phase2-build.log` |
| Whitespace | Staged/unstaged checks pass | Local `git diff --check` checks |
| CI workflow | YAML validated; `tool/` formatting and serial native baseline/gallery targets added | `baseline-phase2-ci.log`, `.github/workflows/flutter-baseline.yml` |

New focused checks cover readable primary/surface/destructive/selection color
pairs (at least 4.5:1), English/Urdu fonts and direction, focused/error/hover/
disabled states, minimum controls and growing rows, invalid and valid form saves,
busy-action keyboard suppression, Tab/Enter and Escape dialogs, interactive
language/brightness switches and Retry at 150% text in a 79-pixel pane.
Native cases render the actual fonts at the 1024×720 outer window minimum;
screenshots capture controls/validation, feedback and dialogs in all four modes.

Failures were resolved before closeout:

- Initial gallery assertions ran before the field's automatic scroll or theme
  animation finished. Bounded pumps and renewed visibility checks repaired the
  fixtures; callbacks, validation and layout assertions remain mandatory.
- The first screenshot refresh failed Windows assembly because the host disk
  filled. Only the resolved workspace `.dart_tool/flutter_build` generated cache
  was removed (about 5 GB); source, store data and retained screenshots were not
  deleted. The final native target and ordinary build both pass.
- The first full-suite attempt passed 535 cases and the optional skip, then
  Flutter failed deleting an already missing default temporary listener directory
  while finalizing the stock-screen test. The runner was stopped and the full
  exit gate rerun with command-scoped `TEMP`/`TMP` under `build/phase2-temp`.
  All 545 cases pass. This required retry is recorded rather than claiming the
  failed attempt was green; SDK code and application assertions were unchanged.

The full suite was reserved for the phase exit; the failed infrastructure attempt
required one retry. Its raw evidence is `baseline-phase2-full-suite.log`.
The same optional `STORE_COPY_PATH` skip retains the Phase 0 user waiver. No new
waivers were introduced. Hosted CI has not run; the existing 28-scenario feature
baseline was not redundantly rerun for the opt-in gallery foundation. Phase 2 is
complete, and Phase 3 is next; Sales restructuring has not started here.
