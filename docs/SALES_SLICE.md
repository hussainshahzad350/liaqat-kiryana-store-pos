# Sales vertical slice

**Complete — 2026-10-04:** 56 focused cases across the recorded checks, all 20
native scenarios and the 549-test phase-end suite pass (one optional skip).
Eight accounting snapshot pairs match; 19 protected hashes are unchanged.
Formatting, analysis and the normal Windows debug build pass.

Phase 3 migrates Sales to the opt-in UI foundation. It preserves the SQLite v5
schema and all SalesBloc events, state fields, repository calls and persisted
money/stock/ledger semantics. Other features retain their current themes until
their own Phase 4 slices.

## Responsibility map

| Owner | Responsibility |
| --- | --- |
| `SalesScreen` | Controller/focus/timer lifecycle, shortcut wiring, event forwarding and composition |
| `SalesWorkspace` | KPI/toolbar/pane composition, shared desktop breakpoints and loading overlay |
| `SalesProductPanel` / `ProductCard` | Search, responsive selection tiles, keyboard focus and no-results feedback |
| `SalesCartPanel` / `CustomerSection` / `CartItemRow` / `SalesTotalsSection` | Customer selection, editable cart inputs, displayed totals and checkout affordance |
| `SalesFeedbackListener` | Controller synchronization, localized error/retry/success feedback and completed-invoice forwarding |
| `SalesDialogs` | Add-customer, credit-warning/increase-limit, checkout, completion and cancellation dialog routing |
| `CheckoutPaymentDialog` | Existing payment-entry validation and InvoiceProcessed forwarding |
| `SalesBloc` | Search/load state, cart calculations, stock validation, payment validation and repository orchestration |
| Repositories/database | Atomic invoices/items, stock events/cache, cash entries, customer ledger/cache, cancellation links and receipt tracking |

The screen now has 346 lines. Dialog routing and feedback are separate
presentation adapters. `SalesWorkspace` receives already composed panels and
SalesState; it never calculates or persists a sale.

## Retained application contracts

- SalesStarted loads products and recent invoices; ProductSearchChanged and
  CustomerSearchChanged retain their existing debounce and search behavior.
- CustomerSelected, ProductAddedToCart, CartItemUpdated, CartItemRemoved,
  CartCleared and DiscountChanged retain their types and payloads. Money stays
  in integer paisas; cart totals remain in SalesBloc/domain code.
- InvoiceProcessed retains cash, bank, credit, change and languageCode. The bloc
  rejects invalid amounts/splits, validates stock, obtains customer/shop data,
  posts through createInvoiceWithTransaction, then loads the saved invoice.
  Repository transactions remain the authority for financial integrity.
- InvoiceCancelled retains its reason/actor and append-only linked reversal
  semantics. Duplicate cancellation remains rejected without additional writes.
- QuickCustomerAddRequested and CustomerCreditLimitUpdateRequested keep their
  validation, repository writes and response fields. Existing warning/override
  routing is retained; presentation does not bypass repository enforcement.
- Print/export retain their existing backend and cancellation behavior. The
  redesign introduces no additional financial writes.

## UI and feedback contracts

Sales scopes `AppUiTheme.fromTheme` to its own subtree, retaining the active
palette, brightness and English/Urdu font. Dialog routes capture that same
theme. Search/customer/cart fields inherit semantic focus/error borders;
checkout uses the foundation button states and minimum control height.
Long grand-total and Urdu checkout labels can wrap inside bounded panes.
Normal-stock badges use readable foreground/background pairs.

Loading retains the blocking overlay. Product searches and recent invoices now
show localized empty states; cart/customer empty states remain explicit.
Errors use localized snackbars with Retry, which dispatches SalesStarted and
preserves the cart. Retry refreshes data; it does not resubmit a payment.
Successful posting opens the existing completion dialog; printer/limit feedback
retains localized success messages.

F9, Escape, Ctrl+F, Ctrl+N, Ctrl+Shift+N and Ctrl+P remain unchanged. Native
checks exercise Tab/Shift+Tab, Enter, modal dismissal, minimum-window checkout,
navigation away/back, customer selection and receipt actions.

## Review evidence and reproduction

Evidence is generated under `build/sales-phase3-review/` on disposable databases:

- `before-en-minimum.png` / `before-ur-minimum.png` retain the existing native
  minimum-window Sales captures before migration.
- `after-{en,ur}-{light,dark}-{empty,no-results,cart,checkout}.png` capture actual
  Windows fonts and direction. Checkout captures its overlay route rather than
  the shell beneath it.
- Eight `before-*.json` / `after-*.json` pairs cover cash, bank, credit and mixed
  payments, both posted and cancelled. The fixture snapshots every application
  table, including invoice items, stock events/caches and cash/customer ledgers.
- `protected-before.json` records SHA-256 hashes of 19 protected implementation
  files. The comparison also checks these files remain unchanged.

The retained before captures come from the completed keyboard/backup flow;
the new visual cases use fresh fixture data. They document layout and styling,
not a pixel-identical data scenario. Persisted outcomes are compared separately
using the matched accounting fixtures.

The optional snapshot exporter strips date/time columns, generated invoice
numbers and transaction IDs across separate fixture runs. The comparison strips
only the cancellation clock inside invoice notes; amounts, balances, quantities,
statuses, row IDs, payment modes, references and reversal links remain compared.
This normalization does not relax the existing accounting assertions.

```powershell
$env:PHASE3_EVIDENCE_SIDE = 'before' # run before editing presentation
flutter test --no-pub test/integration/protected_workflows_test.dart --plain-name 'sale posts exact paisas'
$env:PHASE3_EVIDENCE_SIDE = 'after'
flutter test --no-pub test/integration/protected_workflows_test.dart
Remove-Item Env:PHASE3_EVIDENCE_SIDE
./tool/compare_sales_evidence.ps1
flutter test --no-pub test/widget/sales_slice_test.dart
flutter drive --debug --dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false --driver test/support/desktop_driver.dart --target test/desktop/desktop_smoke.dart -d windows --no-pub
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --no-pub
flutter test --no-pub
flutter build windows --debug --no-pub
```

Native and VM SQLite tests/builds run serially. The full suite runs once at the
phase boundary after focused checks. Local TEMP/TMP may point to
`build/phase3-temp` to avoid the host's previously observed listener cleanup
problem. CI includes the four new visual cases in its baseline aggregator.

## Migration and rollback

This slice changes presentation, tests and documentation only. Reverting the
Sales presentation files and the scoped theme call restores previous visuals;
no data migration or financial reversal is needed. There is no PR created in
this local task, so screenshots/logs remain reviewable workspace artifacts.
Physical printing and a populated real-store copy remain the previously waived
checks; native fixtures use disposable stores and the existing print test backend.
