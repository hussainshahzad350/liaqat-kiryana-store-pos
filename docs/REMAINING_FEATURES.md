# Remaining feature slices — Phase 4

Phase 4 applies the shared presentation system to the remaining desktop routes.
The existing state owners, repository calls, events and persistence boundaries
remain in place. The phase-start SHA-256 snapshot covers 62 files across BLoCs,
repositories, database, domain, models, services and the cash controller.

## Responsibility map

| Area | Presentation composition | Existing state/data owner |
| --- | --- | --- |
| Products | ProductScreen and AppManagementTabs; ItemsToolbar/ItemsTable; category panes and unit dialogs | ItemsScreen paging coordinator, CategoriesBloc, UnitsBloc and existing catalog repositories |
| Accounts | AccountsScreen and AppManagementTabs; existing customer/supplier lists, forms and ledgers | Existing account screens/BLoCs and customer/supplier repositories |
| Stock/purchases | Themed root builders, stock tables, activity panes and purchase product/cart widgets | StockOverviewBloc, StockActivityBloc, StockUiCubit and PurchaseBloc |
| Cash | Themed provider composition, localized search and recoverable ledger list | CashLedgerController and CashRepository |
| Settings | Themed settings composition and existing backup/security forms | SettingsCubit and existing settings/backup services |
| Authentication/shell | Themed login, navigation sidebar and header | Existing authentication, session, navigation and theme owners |

AppFeatureTheme supplies the shared font, colors, controls and feedback roles.
Its builder supplies the themed context used to open feature dialogs.
AppManagementTabs owns only the common title/tab frame. Feature providers and
keep-alive behavior remain in the feature views. AppPaneViewport gives dense
category panes a bounded horizontal viewport at narrow desktop widths.

## State and layout contracts

- Items retain generation-guarded paging and filters. Initial load failures have
  a localized retry state; paging failures keep existing rows visible and offer
  retry. No offset, limit, sorting or repository semantics change.
- Categories and units use localized loading/error states with their existing
  reload events. Category panes scroll horizontally rather than overflowing.
- Catalog and stock table rows may grow for real Urdu font metrics; unit rows
  have a minimum height rather than a fixed height that clips text.
- Purchase empty results and cash loading/empty/error states use AppStateView.
  Cash retry invokes the existing refresh method and preserves controller rules.
- Unit base/derived conversions, system-unit protection and archive/delete
  rules remain in their existing validators, BLoC and repository.
- Account balances, invoice/purchase cancellation, stock adjustments, payment
  processing, backup/restore and authentication behavior remain unchanged.

## Evidence and rollback

Native visual evidence is retained in `build/remaining-phase4-review/`: English
and Urdu, light and dark, at 1024×720. Baseline capture recorded category layout
errors and saved 36 images; English cash/settings were not captured because the
baseline fixture incorrectly required a transparent root to be hit-testable.
The corrected fixture still fails on every Flutter layout exception in after
mode. Baseline failures are retained in the local logs.

New native taxonomy/unit scenarios edit a department and create/edit/delete an
unused derived unit, then compare system units and twelve protected tables.
The combined desktop harness also retains all earlier workflows. New widget
checks cover catalog retry with retained rows and unit reload in both languages
and brightness modes.

No schema migration or data conversion is required. Rollback is limited to the
Phase 4 presentation components and their feature call sites; retain the existing
state/data owners and all earlier-phase work. Physical printing and a populated
real-store copy retain the earlier explicit waiver.

Reproduce the complete desktop matrix with 

    flutter drive --debug --dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false --driver test/support/desktop_driver.dart --target test/desktop/desktop_smoke.dart -d windows --no-pub

The focused remaining slice target registers six cases; the Phase 4 repair
target registers payment, keyboard/navigation and product CRUD cases. The latter
keeps all keyboard and persisted outcome assertions after the narrow-window form
repair and bounded cart wait. The native fixture restores an inactive OS window
without requesting focus for an individual widget.



Phase exit: 557 VM tests pass with one optional store-copy skip; all 38 native
scenarios have passing evidence across the matrix and focused repairs. Analysis,
282-file formatting, localization generation and the ordinary Windows debug
build pass. See BASELINE.md for exact results and retained failure/repair logs.
