<!-- Phase records below are historical; the subsequent cleanup is documented in CLEANUP_AUDIT.md and BASELINE.md. -->

# Liaqat Store POS Restructuring Plan

Architecture and all five presentation redesign phases are complete. Results follow
[UI_UX_IMPLEMENTATION_PLAN.md](UI_UX_IMPLEMENTATION_PLAN.md), based on the
[UI audit](UI_UX_AUDIT.md) and its protected business behavior boundary. See the
[UI completion record](UI_UX_COMPLETION.md) for verification and screenshot comparisons.

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
9. Use focused tests during individual steps; run the full suite at each phase's
   exit gate, as requested by the user on 2026-10-04. Fix discovered bugs under
   the user's standing authorization without separate correction approval.

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

**Status: COMPLETE — 2026-10-04**, with physical-printer verification and
populated real-store diagnosis/upgrade explicitly skipped at the user's request.

Tasks:

- [x] Record the restructuring strategy and protected boundaries.
- [x] Record the initial repository inventory and known verification gap.
- [x] Mark historical audit documents as snapshots rather than current truth.
- [x] Locate and use the installed Flutter SDK (3.44.4 / Dart 3.12.2).
- [x] Run dependency resolution, localization generation, analysis, and all
      tests in a fresh checkout with the candidate changes applied.
- [x] Launch disposable fresh desktop databases and record smoke-check outcomes.
- [x] Record the user's waiver of populated real-store diagnosis/upgrade
      validation on 2026-10-04. Historical synthetic upgrade checks remain passed;
      a populated real store is not claimed as validated.
- [x] Record failures, fixes and rerun evidence separately in `BASELINE.md`.
- [x] Add Windows CI for locked dependencies, localization, formatting, analysis,
      the full suite, native desktop scenarios and a normal debug build.

Current evidence: see **Phase 0 closeout — 2026-10-04** in `BASELINE.md`.
The phase-end full suite passes **494 tests**, with **one optional store-copy
check skipped**. All **28 distinct native Windows scenarios** have passing
evidence: 26 passed in the aggregate run; the two affected keyboard scenarios
passed after a fixture-lifetime repair in the four-test keyboard rerun.
Analysis, formatting of all 259 Dart files, locked dependency resolution,
localization regeneration and the normal Windows debug build pass. CI is
configured and structurally validated; hosted CI has not yet run.
The earlier 425-test candidate also passed in a fresh checkout with candidate
changes applied. Physical printing and a verified populated real store are
waived checks, not claimed passes.

Next bounded work items, in order:

1. [x] Capture all eight failures and finish SDK, formatting, dependency, and
   localization checks. The initial 99-file formatting drift and 14 missing Urdu
   messages are resolved in item 8 below.
2. [x] Repair test infrastructure: nullable factory restoration, temporary
   databases, safe setup/teardown, and explicit consistent ledger fixtures.
3. [x] Align settings tests with the Security category and verify its navigation.
4. [x] Repair unit normalization SQL quoting, with a regression test covering
   category names, stable unit IDs, repeated execution, and unchanged schema.
5. [x] Give fresh sample stock and customer balances matching opening events;
   verify sale/cancellation, purchase/cancellation, and payment on unmodified
   fresh databases. Existing stores are not rewritten.
6. [x] Repair nonzero opening balances in `CustomersRepository.addCustomer`:
   atomic creation, signed opening entries, duplicate protection, and rollback
   coverage. No existing customer data is rewritten.
7. [x] Record the user's waiver of populated real-store diagnosis on 2026-10-04.
   The captured empty workspace copy's diagnosed mismatches remain documented;
   neither source rows nor customer/store data are modified.
8. [x] Complete all 14 missing Urdu entries, regenerate localization, and apply
   a separately recorded formatting pass. All 228 Dart files pass formatting.
9. [x] Re-run dependency resolution, localization generation, analysis, and the
   full suite in a fresh checkout with the candidate changes and the same SDK.
10. [x] Complete disposable fresh-desktop smoke checks, record the populated-store
    waiver and add CI. See the final closeout evidence.
11. [x] Verify and repair backup creation, listing, unique names, WAL snapshots,
    and retention using temporary databases. Five regression cases pass.
12. [x] Repair and verify the helper connection lifecycle first, then repair
    repository restore validation, staging, emergency snapshots, rollback,
    and overlapping-call protection. Two lifecycle and eleven restore cases
    pass, including comparison of every table's rows. Historical-schema and
    real-store-copy upgrade validation still belong to the open baseline gates.
13. [x] Freeze version 1–4 schema definitions from Git history and test upgrades
    through normal open and restore with populated sales/purchase/ledger data.
    Repair the reproduced version-1 duplicate-column migration failure without
    changing the column definition or stored values. Nine cases pass.
14. [x] Repair the native desktop layout failures in a separate presentation
    change: product card at 1024×720; Urdu product card, header and empty cart.
    All four desktop scenarios pass, including Urdu at the minimum window size.
    Screenshots are retained; the full workflow and real-store-copy gates remain.
15. [x] Exercise desktop PIN lockout/recovery/logout and the four payment modes
    with persisted sale/cancellation outcomes on disposable databases. All five
    scenarios pass after the customer-dropdown Material ancestor repair.
16. [x] Capture the existing default workspace database through a read-only
    source connection; verify open/backup/restore on a temporary copy and retain
    count-only diagnostics. It contains no sales or purchases, so this does not
    close item 7 or the real-store upgrade gate. One stock and one customer
    cache/ledger mismatch were diagnosed; no source rows were changed.
17. [x] Reproduce and repair lost sales keyboard focus after customer selection.
    Verify F9, Escape, Ctrl+F, Ctrl+N and Ctrl+Shift+N on native Windows and run
    the four payment/cancellation workflows through F9. Full Tab traversal and
    Urdu keyboard interactions remain in the open desktop gate.
18. [x] Extend native checkout validation: reject named-customer overpayment
    and walk-in underpayment; display walk-in change and persist only the sale
    total as cash inflow, preserving existing customer rows and ledger.
19. [x] Verify English/Urdu sidebar navigation and account tabs on Windows.
    Repair the stock-table header overflow by allowing horizontal scrolling.
    Verify invalid purchase input, purchase creation and supplier payment through
    Accounts, with persisted stock, supplier ledger/balance and cash effects.
    Remaining workflows still belong to the open full-workflow gate.
20. [x] Verify zero/valid customer payments in English/Urdu and purchase
    cancellation from activity history, with persisted receipt/cash/ledger/stock
    effects and repeat-request protection. Repair activity-table/detail scrolling.
21. [x] Resolve the P1 mixed-timestamp balance defect under the user's explicit
    authorization to fix bugs discovered in tests. Current customer/supplier
    running balances now follow ledger append order for receipts, sales,
    purchases, payments and reversals. The formerly failing receipt regression
    is mandatory; three repository regressions cover mixed/backdated entries.
    Native English/Urdu repeated receipts persist the correct negative balance.
22. [x] Close stale stock activity details after successful actions. Reopening
    a cancelled purchase shows its current status without a cancellation action;
    duplicate repository cancellation leaves stock and supplier ledgers unchanged.
23. [x] Verify English/Urdu stock adjustment and cash-ledger workflows on native
    Windows: invalid input, +5/-7 stock events, zero cash rejection and exact
    paisa cash in/out. Repair the reproduced 27-pixel Urdu cash-row overflow.
    All five combined receipt/cancellation/stock/cash scenarios pass.
24. [x] Reproduce and fix supplier opening-balance integrity and stale account
    edits. Supplier creation and its signed opening entry are atomic; duplicate
    IDs cannot replace history. Metadata edits preserve the current customer/
    supplier balance cache. Six new regressions and 78 affected tests pass.
25. [x] Verify customer/supplier create/edit/archive/restore in English and Urdu
    on Windows, with required fields, precise amounts and unchanged financial
    history. Localize supplier add/archive headings and archived names.
26. [x] Repair the catalog's repeated-first-page loading and add a visible Items
    entry from stock. Verify distinct pages, search reset and archived filtering.
    Reject whitespace names, allow clearing brands and preserve creation timestamps.
27. [x] Verify product create/edit/archive in English/Urdu on native Windows,
    including category/unit selection and archive decline/confirm. Existing stock,
    prices, timestamps and financial history remain unchanged. Six focused checks
    and both native scenarios pass; the full suite remains reserved for phase end.

28. [x] Verify English/Urdu receipt generation, desktop print/save buttons,
    cancellation and one print request per click using a test printer backend.
    Preserve fractional quantities/paisas, saved names and payment details;
    honor receipt paper/font/visibility settings and paginate long receipts.
    Remove an export write to a nonexistent column. Eight focused tests and two
    native scenarios pass; financial records and the schema remain unchanged.

29. [x] Complete English/Urdu keyboard-only checkout, sidebar/account/settings
    navigation, backup/restore and logout at 1024×720. Compare every restored
    table's rows and retain foreign-key checks. Repair reproduced focus and
    minimum-height layout defects; retain screenshots and passing rerun evidence.
30. [x] Add a single 28-scenario desktop entry point and Windows CI workflow.
    Validate workflow structure and run its checks locally with SDK 3.44.4.
31. [x] Run the phase-end full suite once: 494 passed, one optional store-copy
    check skipped. Analysis and formatting pass; restore the normal Windows
    executable with a successful debug build after native testing.

No Phase 0 work remains within the user-amended scope. Physical-printer
verification and populated real-store diagnosis/upgrade were explicitly waived
on 2026-10-04; these are skipped checks, not passing checks. Historical entries
above describe the gates that were open at each intermediate step. Phase 1 is
next; test repairs retain existing financial expectations.

Exit criteria:

- The exact Flutter/Dart versions are recorded.
- `flutter analyze` and `flutter test` have reproducible results.
- Fresh-install smoke tests have recorded outcomes. Existing-database checks
  record synthetic historical upgrades and the user's populated-store waiver.
- Known failures have owners and severity rather than being hidden.

### Phase 1 — Protect business-critical workflows

**Goal:** Build a regression harness around existing behavior.

**Status: COMPLETE — 2026-10-04.** The harness adds 26 persisted workflow cases
and two money cases, retaining the existing backup/restore/upgrade and accounting
regressions. See `PHASE_1_REGRESSION_HARNESS.md` for named tests and expected
effects. The final focused run passes 35 tests; the phase-end full suite passes
522 tests with the same optional store-copy check skipped. Analysis has no issues
and all 260 Dart files pass formatting. This phase changes tests/documentation
only; no production behavior or schema changes were needed.

Completed coverage:

1. [x] Cash, bank, credit and mixed sales with exact paisas and linked reversals.
2. [x] Walk-in overpayment, credit rejection and invalid payment rollback.
3. [x] Insufficient stock, later-item rollback and competing checkouts.
4. [x] Sale cancellation, concurrent/repeated requests and exactly-once reversals.
5. [x] Purchase creation/cancellation, consumed-stock rejection and atomic retry.
6. [x] Customer/supplier payments, balance caches and final-write rollback.
7. [x] Backup, restore and historical database upgrades, retaining existing tests.
8. [x] Integer-money round trips, saved discount totals and precise display.

Exit criteria:

- [x] Every protected workflow has named tests and expected ledger/stock effects.
- [x] Fixtures use isolated temporary databases with asserted safe paths.
- [x] Tests check persisted rows, cache/ledger effects and rollback outcomes.
- [x] Phase-end analysis, formatting and the full suite pass.

No Phase 1 work remains. Phase 2 is next. The Phase 0 user waivers remain in
effect; synthetic fixtures do not claim physical printing or real-store proof.

### Phase 2 — Establish the UI system

**Goal:** Improve consistency before redesigning individual screens.

**Status: COMPLETE — 2026-10-04.** `UI_SYSTEM.md` records the semantic roles,
component inventory, states, desktop layout and keyboard contracts. The opt-in
`AppUiTheme` and shared action/dialog/table components are proved in
`tool/ui_gallery.dart`; existing feature theme adoption remains scoped to Phases
3 and 4. Production minimum-window/settings-grid rules now call shared constants
without changing their values. No financial logic, database schema or repository
changed in this phase.

Tasks:

- [x] Define a small semantic token set for spacing, typography, color, radius,
  elevation, density, and focus states.
- [x] Inventory shared buttons, form fields, dialogs, cards, tables, empty states,
  loading states, and error states.
- [x] Define desktop breakpoints and the minimum supported window behavior.
- [x] Define keyboard navigation and shortcut conventions for counter operation.
- [x] Create English and Urdu/RTL visual test cases in light and dark themes.
- [x] Build a non-production component gallery and focused widget tests before
  replacing feature UIs.

Exit criteria:

- [x] New foundation/gallery components use semantic colors, spacing and typography.
- [x] Shared components have light/dark and LTR/RTL examples.
- [x] Focus, hover, disabled, loading, validation and error states are specified.
- [x] 23 focused tests and all four native gallery scenarios pass; twelve visual
  captures retain actual English/Urdu font rendering at the minimum window.
- [x] Phase-end full suite: 545 passed, one optional store-copy check skipped.
  Analysis and formatting of 268 Dart files pass; normal Windows build restored.
- [x] CI includes `tool/` formatting and the native gallery target; YAML validated
  locally. Hosted CI execution is not claimed.

No Phase 2 work remains. Phase 3, the Sales vertical slice, is next. Existing
feature styling differences are documented migration work rather than silently
changing every screen through the global theme.

### Phase 3 — Sales vertical slice

**Goal:** Prove the restructuring method on the most important workflow.

**Status: COMPLETE — 2026-10-04.** `SALES_SLICE.md` records responsibilities,
retained application/repository contracts, presentation migration and review
evidence. All 20 affected native scenarios pass; the phase-end suite passes
549 tests with one existing optional skip. Analysis, formatting of 274 Dart
files and the normal Windows debug build pass.

Completed work:

1. [x] Capture current sales behavior and screenshots.
2. [x] Document `SalesBloc` inputs, outputs, and repository contracts.
3. [x] Reduce `sales_screen.dart` to controller lifecycle, event forwarding and
   composition; extract workspace, dialog routing and localized feedback.
4. [x] Keep calculations and persistence outside visual widgets.
5. [x] Redesign product selection, cart, customer selection, totals, payment, and
   recent-sales states using the UI system.
6. [x] Verify keyboard-only checkout and Urdu/RTL behavior in native Windows;
   include light/dark minimum-window visual states and themed dialogs.
7. [x] Compare persisted invoices, stock, cash and ledger entries before/after:
   eight matched snapshots; all 19 protected implementation files unchanged.

Exit criteria:

- [x] No protected persisted outcome changes.
- [x] The sales screen has explicit loading, empty, error/retry and success states.
- [x] The complete checkout flow works with mouse and keyboard.
- [x] Before/after screenshots and test evidence are retained locally for review
  in `build/sales-phase3-review/`; no PR was requested or created.
- [x] Phase-end format, analysis, full-suite and normal Windows build gates pass.

No Phase 3 work remains. Phase 4 closeout is recorded below.

### Phase 4 — Remaining features, one slice at a time

**Status: complete — 2026-10-04.** All six slices were completed in one pass.
The shared presentation theme and management frame preserve the existing state
owners, events, repository calls and persistence contracts. See
[REMAINING_FEATURES.md](REMAINING_FEATURES.md) for the responsibility map,
state/layout contracts, reproduction and rollback notes.

1. [x] Products: items, categories and units; recoverable catalog states, readable
   Urdu table/unit rows and horizontally scrollable dense category panes.
2. [x] Accounts: customer/supplier management, forms and ledgers adopt the shared
   presentation boundary; native account CRUD/payment assertions are retained.
3. [x] Stock and purchases: shared theme, growing table rows, empty results and
   themed dialogs; adjustment, purchase and cancellation outcomes verified.
4. [x] Cash: localized search and loading/empty/error/retry presentation; existing
   refresh, paging, payment-mode and date-filter rules retained.
5. [x] Settings, backup and security: themed composition with existing providers
   and pages; backup/restore and authentication/recovery checks preserved.
6. [x] Authentication and shell: shared login/header/sidebar presentation,
   keyboard navigation and English/Urdu minimum-window checks.

Exit criteria:

- [x] All 62 phase-start protected implementation hashes remain identical.
- [x] All 38 distinct desktop scenarios have passing evidence across the complete
  matrix and focused repairs; real Tab/Enter/F9 and persisted assertions remain.
- [x] Forty after screenshots cover ten panes in both languages and brightness
  modes at 1024×720; 36 baseline captures and failure logs remain for review.
- [x] Full phase-end suite: 557 passed, one optional store-copy check skipped.
- [x] Analyzer, formatting of 282 Dart files, stable localization generation,
  whitespace checks and ordinary Windows debug build pass.

No Phase 4 work remains. Phase 5 is the next planned work.

### Phase 5 — Deliberate cleanup

**Status: complete — 2026-10-04, under the retained physical-printer and populated
real-store waivers.** Cleanup stayed within unused presentation helpers,
development tooling and documentation. All 69 captured protected implementations
remain unchanged. See CLEANUP_AUDIT.md and PERFORMANCE.md for decisions and limits.

- [x] Re-run unused-symbol and call-site audits: compiler-backed analyzer plus
  repeatable import/public-symbol inventory; 195 production-reachable libraries.
- [x] Classify candidates: active, planned, compatibility-only and removable;
  retain 16 reviewed unwired libraries with explicit reasons.
- [x] Remove three confirmed unused files: obsolete theme variants, an unused PDF
  presentation helper and an empty utility. No schema or financial changes.
- [x] Replace stale function/task lists and 55 document-shape assertions with a
  live source-audit command and two meaningful graph/manifest tests; add one
  unique-record/seed-preservation fixture check.
- [x] Update README, onboarding, architecture, release, backup/recovery, desktop
  verification and cleanup documentation to match current routes/contracts.
- [x] Measure compiled release startup, search, checkout, deep paging, stock
  paging, posting/reversal and backup on an isolated synthetic-volume copy.

Exit criteria:

- [x] Documentation describes the code that ships, including retained direct
  repository coordinators, compatibility aliases and unsupported feature claims.
- [x] No known duplicate feature screen declarations/alternate implementations;
  legacy routes delegate to canonical Product/Accounts tabs.
- [x] AOT release checks pass for real app PIN/search/cart/cash callbacks and
  protected repository flows on a copied synthetic dataset: 10,001 products,
  2,002 customers, 50 historical invoices and all-table backup/restore equality.
  Actual populated-store provenance and physical printing remain waived; the
  synthetic distribution is not claimed to replace those checks.
- [x] Final full suite: 505 passed, one optional store-copy skip; analysis,
  283-file formatting, audit manifest, CI/script validation and normal release
  application build pass. The shipping entry point is restored after the harness.

All six restructuring phases are complete within the documented scope. Future
work should be separately scoped product improvements or the previously waived
store/printer validation rather than repeating this plan's phases.

### Next work: UI and UX

On 2026-10-04 the user froze functional behavior and requested a complete UI/UX
audit. The [UI/UX audit](UI_UX_AUDIT.md) records native screenshots, prioritized
findings and proposed presentation phases. The [freeze boundary](UI_UX_FREEZE.md)
protects the completed business contracts. This audit does not implement the
proposed UI changes or reopen the completed restructuring phases.

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

Phase 0 outcomes below use disposable desktop databases and persisted repository
assertions. A populated real-store copy and physical printing were waived for
this phase; they are not validated by the synthetic checks.

- [x] Log in, log out, trigger lockout, and complete recovery (native).
- [x] Create/edit/archive a product, customer, and supplier on a disposable desktop
      database (English/Urdu native checks); real-store-copy validation is waived.
- [x] Complete cash, bank, credit, and mixed-payment sales (native/persisted).
- [x] Reject invalid payments (native) and insufficient stock (repository tests).
- [x] Cancel a sale and verify no duplicate reversal (native/repository tests).
- [x] Create and cancel a purchase (native/persisted).
- [x] Record customer and supplier payments (native/persisted).
- [x] Adjust stock and inspect its activity history (native/persisted).
- [x] Add cash-in/cash-out and verify balances (native/repository tests).
- [x] Print/export a receipt in English and Urdu using the desktop test backend
      and visually reviewed PDFs; physical-printer verification was waived by
      the user on 2026-10-04.
- [x] Create/restore a backup; compare all saved table rows (native/repository).
- [x] Navigate and check out using only the keyboard at 1024×720 (English/Urdu).

## 8. Decision log

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-10-03 | Repair incrementally; do not rewrite | Existing domain behavior, migrations, repositories, and tests have substantial value |
| 2026-10-03 | Begin with documentation-only Phase 0 | The current environment has no Flutter executable, so claiming a green runtime baseline would be misleading |
| 2026-10-03 | Use Sales as the first vertical slice | It exercises the greatest concentration of stock, cash, ledger, customer, and receipt behavior |
| 2026-10-04 | Skip physical printing and populated real-store validation for Phase 0 | Explicit user instruction to skip items 2 and 3 and complete the remaining phase in one go |
| 2026-10-04 | Close Phase 0 under the amended scope | Local phase gates pass; failures and repairs are recorded, deferred checks are explicit, and CI is configured |
| 2026-10-04 | Complete Phase 1 in one pass | User authorized uninterrupted work; 28 added regression cases and the retained harness pass the 522-test phase gate |
| 2026-10-04 | Complete Phase 2 as an opt-in presentation foundation | User requested one-pass completion; shared contracts/components and real-font gallery checks precede feature migration, with 545 tests passing |
| 2026-10-04 | Complete Phase 3 as a presentation-only Sales slice | User requested uninterrupted continuation; 20 native scenarios, eight matched accounting snapshots and the 549-test phase gate preserve protected behavior |
| 2026-10-04 | Complete all Phase 4 remaining features in one pass | User requested uninterrupted completion; protected hashes, 38 desktop scenarios and the 557-test phase gate preserve existing behavior |
| 2026-10-04 | Complete Phase 5 under retained store/printer waivers | User requested one-pass cleanup; three zero-caller removals, live audit/CI gates, AOT release workflows, synthetic-volume measurements and 505-test suite pass |
