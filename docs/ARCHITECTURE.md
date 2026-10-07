# Architecture

The running application is offline-first. `lib/main.dart` initializes desktop
SQLite FFI, the window, localization, repositories and theme preferences. Login
uses PinAuthService; the post-login AppShell hosts the feature route registry and
caches selected screens. Stock, Purchase and Product routes are rebuilt on
navigation so their one-shot initial loads see fresh data.

| Responsibility | Current implementation |
| --- | --- |
| Canonical navigation and feature lifetimes | AppShell; app_routes.dart; AppNavigationSidebar |
| Sales state/validation forwarding | SalesBloc; SalesScreen; SalesWorkspace; SalesDialogs; SalesFeedbackListener |
| Catalog/taxonomy/units | ItemsScreen paging coordinator; CategoriesBloc; UnitsBloc |
| Stock/purchase state | StockOverviewBloc, StockActivityBloc, StockFilterBloc, StockUiCubit, PurchaseBloc |
| Account state | CustomerController, supplier/account widgets and existing repositories |
| Cash state | CashLedgerController and CashRepository |
| Settings | SettingsCubit and SettingsRepository |
| Authentication | PinAuthService and LoginScreen |
| SQL transactions/migrations | Existing repositories and DatabaseHelper |
| Presentation roles | AppTokens, AppLayout, AppUiTheme and shared widgets |

This is incremental architecture: some catalog/account widgets still coordinate
repository reads. Documentation does not describe an imaginary fully separated
domain layer. Presentation extraction must preserve state owners and their
contracts. The Sales and remaining-feature responsibility maps provide details.

Canonical features are Sales, Stock, Purchase, Product, Accounts, Cash and
Settings. Legacy `/items`, `/categories`, `/units` requests delegate to Product
tabs; `/customers` and `/suppliers` delegate to Accounts tabs. These aliases retain
one implementation per feature. Logout and login are session transitions.
There are no active Home, Reports or About screen routes.

The database version is 5, declared by DatabaseHelper's open call. Current
transaction tables are `invoices`, `invoice_items`, `purchases`, `purchase_items`,
`receipts`, `supplier_payments`, `customer_ledger`, `supplier_ledger`, `cash_ledger`
and `stock_activities`, with catalog/contact/settings tables alongside them.
Money is integer paisa; quantities and conversion factors retain their existing
numeric semantics. Transactions validate cached stock/balances against history.
Cancellation records reversal events and prevents a second reversal.

Unused production libraries and declaration-only methods were removed after
caller checks. The source audit rejects newly introduced orphan libraries.
Database migrations and active stock/ledger operations keep their behavior.

Receipts use the existing receipt repository, printer helper and local-font PDF
renderer. The unused PdfGenerator was removed; active PdfExportService and
receipt rendering remain. ThemeProvider owns persisted color/mode/RTL settings;
AppFeatureTheme supplies the shared presentation roles at feature boundaries.

Tooling and fixtures live in `tool/` and `test/` (native scenarios in `test/desktop/`). The release
verification target is a separate executable that uses an isolated database and
memory credentials; `lib/main.dart` remains the shipping entry point.
