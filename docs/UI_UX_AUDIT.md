# POS UI/UX audit — 2026-10-04

The application feels crowded because its working space is poorly allocated and its visual hierarchy is inconsistent. Large summary areas, repeated headings, card framing and fixed panels compete with the actual tasks. There is considerable empty space, but much of it sits inside oversized elements rather than between meaningful groups. Adding padding everywhere would worsen this.

This is an audit and a proposed presentation plan. Production code and business behavior remain frozen. See [UI_UX_FREEZE.md](UI_UX_FREEZE.md).

## Evidence and coverage

Open the [searchable screenshot atlas](../.local/ui-ux-audit/index.html). Images are original PNG captures of the running native Windows Flutter render tree. The atlas filters by surface, language and window variant. Contact sheets provide an overview; click an original image to inspect text and fine detail.

The final evidence contains **400 screenshots** and **38 contact sheets**: 129 screen captures, 101 dialog captures, 138 snackbar captures, 18 ledger/archive overlays, four export sheets, six menus and four stock panels. The 138 feedback images cover 68 source locations in English and Urdu plus the settings helper's error branch. Evidence is stored in `.local/ui-ux-audit/`, outside generated build output, so `flutter clean` does not remove it.

Coverage includes all seven canonical workspaces; Product's Items/Categories/Units tabs; Accounts' Customers/Suppliers tabs; customer/supplier ledgers and archives; all five settings pages; login, recovery and PIN setup/reset/error/lockout states; cart/search states; stock selection/menu/history/activity panels; ledger export sheets; all 34 named dialog variants; eight inline dialogs; Material date/date-range pickers; and all 68 snackbar constructor locations in both languages.

Main screen variants use English and Urdu, light mode at 1366×768 and 1024×720 outer window sizes, and dark mode at 1024×720. Dialog and snackbar specimens use English/Urdu light mode; selected large forms additionally use the minimum window size. Windows title-bar/border space reduces the captured client size to approximately 1350×729 and 1008×681 at this machine's scale. The manifest records the actual capture dimensions.

**Evidence distinction:** screen navigation, overlays, menus and PIN states exercise live production UI on disposable data. The item-validation specimen mounts the production dialog from the shell context and executes its empty-form validation. Other dialog specimens render the real production widget with sample data and inert callbacks. Inline dialog and snackbar specimens reproduce their source constructors; dynamic text uses labeled sample values. These prove appearance, not successful execution of those business operations. All 68 locations are represented; every possible exception string, amount and conditional message is not an enumerable set. OS file pickers, Windows chrome and physical printer dialogs are outside the Flutter render surface. This audit does not claim a complete accessibility certification or a new functional acceptance test.

The inventories map specimens to their exact source locations:

- [Feedback inventory](ui-ux-audit/feedback-inventory.json)
- [Inline dialog inventory](ui-ux-audit/inline-dialog-inventory.json)
- [Production freeze hashes](ui-ux-audit/production-freeze.json)
- [Capture manifest](../.local/ui-ux-audit/captures.json)
- [Capture totals and observed errors](../.local/ui-ux-audit/summary.json)

## Highest-priority findings

P1 means a substantial obstacle to reading, navigating or completing a task. P2 means recurring visual friction or inconsistency. P3 means polish. These priorities concern presentation; they do not imply changes to accounting rules.

| ID | Priority | Observed problem and consequence | Recommendation | Evidence |
| --- | --- | --- | --- | --- |
| UX-01 | P1 | The customer ledger filter row overflows by 43 px and the supplier row by 68 px in English at the supported minimum size, in light and dark modes. Their fixed 350 px searches plus date/segment controls exceed the available pane. Controls visibly run beyond the surface. | Base layout on the ledger's available width. Use a flexible search field and move filters to a second row when needed. Keep date/search/filter actions available and preserve callbacks. | `en-light-min-customer-ledger`, `en-light-min-supplier-ledger`; `customer_ledger_panel.dart` and `supplier_ledger_panel.dart`, `_FilterBar`. |
| UX-02 | P1 | Stock's total-cost summary shows `Rs 191,…` at the wider size and `Rs …` at minimum size. Seven equal-width cards force labels onto inconsistent numbers of lines. A financial total cannot be understood from the summary. | Give the financial total sufficient minimum width. Use fewer primary summaries and a secondary summary region that wraps without truncating amounts. Align card content heights. | `en-light-wide-stock`, `en-light-min-stock`, Urdu counterparts; `kpi_strip_widget.dart`. |
| UX-03 | P1 | Stock's two vertically split tables leave only a few visible inventory rows. At minimum size the recent-activity pane can display its heading/header with almost no transaction content. Action columns require horizontal scrolling. | Give inventory the main working area; present activity as a secondary tab, collapsible region or detail view with an explicit affordance. Keep all existing stock/history operations reachable. Pin important identity/action columns where practical. | `en-light-min-stock`, `ur-light-min-stock`; `stock_screen.dart`. |
| UX-04 | P1 | At the minimum client width, the 250 px sidebar and 450 px cart leave about 276 px for Sales product selection. The product grid becomes one wide tile per row. A fixed 200 px Recent Sales card competes with the grid even when empty. | Use a compact navigation rail at constrained sizes; size the cart from the available workspace; keep checkout visible; make recent history secondary or collapsible. Preserve tab order and existing shortcuts. | `en-light-min-sales`, populated/collapsed-sidebar captures; `app_layout.dart`, `sales_workspace.dart`, `recent_sales_section.dart`. |
| UX-05 | P1 | Accounts spends roughly the first two-thirds of the wide client's height on header, repeated title, tabs, toolbar, summary cards and search. The list shows only about two full customers although 25 exist. Individual entries are also elevated cards within an elevated list card. | Combine page title, local tabs and primary action into a compact page structure. Replace large summary cards with a quiet strip; keep search inline; use flatter consistent rows. Target at least twice the current visible record count while retaining readable Urdu text. | `en-light-wide-customers`, `ur-light-wide-customers`, supplier counterparts; account/list/KPI widgets. |
| UX-06 | P1 | Urdu navigation, tab labels and metadata look much smaller than nearby headings and English numerals. Some labels remain English: supplier ledger `Make Payment`/`Total Payable`, cash `All Dates`, unit/category names, and supplier deletion. | Establish Urdu-specific font metrics and line height through real text measurement. Separate numeric/code spans from prose and retain stable number direction. Localize UI labels; treat user-entered/catalog names separately. Verify actual user readability before choosing sizes. | Urdu screen/dialog captures; `app_themes.dart`, `app_ui_theme.dart`, supplier ledger, cash search. |
| UX-07 | P1 | Stock CSV/PDF and bulk adjustment/export actions display a snackbar instead of completing the operation. Their normal action styling gives the impression that they work. | Present the existing unsupported status honestly through copy/disabled presentation or clear explanatory feedback. Implementing exports or bulk operations is outside this UI freeze. | `stock_screen.dart`, toolbar/bulk callbacks; feedback inventory. |
| UX-08 | P1 | Several error snackbars expose raw exception text, including `Error saving: …`; validation uses disappearing global messages in some forms. Item validation feedback remained visible after navigating to Settings. Success/default/error palettes vary between features. | Centralize semantic feedback presentation. Keep field errors next to the relevant input; associate transient messages with their task; use concise persistent feedback for an unresolved operation failure; keep technical details in logs. Apply existing validators without changing their rules. | Snackbar specimens, item-form-validation and settings-receipt-lower captures; item, cash, backup and sales feedback sources. |
| UX-09 | P2 | Header, tabs, toolbar, search, table and detail sections have different alignment edges. Purchase abuts panels; Sales cards touch at the dividing seam; Stock's data table ends before its enclosing surface. Repeated borders and shadows make these joins look broken. | Use one workspace gutter/grid and align headings, fields, tables and actions to it. Use a single surface per logical region and quieter dividers. Make nested surfaces exceptional. | Wide Sales/Purchase/Stock/Accounts captures. |
| UX-10 | P2 | The sidebar's Products & Stock item contains a further Items navigation step, while Product can have no matching selected sidebar item. Cash Ledger is reachable through Sales context rather than a clear global location. Page names repeat across header/body. | Present global section, local workspace and current tab as a consistent hierarchy. Ensure an active navigation indication for every existing workspace; preserve route destinations. Decide whether cash is an Accounts sub-entry or a clearly labeled Sales shortcut. | Product/Cash captures; `app_navigation_sidebar.dart`, `app_shell.dart`. |
| UX-11 | P2 | Dialog titles, close affordances, button labels/order and spacing vary. Unit dialogs say Add/Edit Item rather than Unit. Delete confirmations say “this item,” and supplier deletion says “completely delete” although the current action deactivates the supplier. Checkout's initial disabled action does not explain what payment is missing. | Standardize modal header/body/footer roles. Name the affected record and accurately describe the existing operation. Explain unmet validation requirements inline. Do not change confirmation logic or posting rules. | Named dialog specimens, inline-08; unit dialog files and supplier delete handler. |
| UX-12 | P2 | Green/gray surface tint is used on most regions, colored summary cards receive attention before working lists, and Stock's Expired count uses a pale error-container color as foreground. In dark mode some surfaces differ only subtly. | Reserve stronger color for active navigation, the primary action and genuine status. Use neutral workspace surfaces, measured text contrast and appropriate foreground/background color pairs. Avoid encoding status through color alone. | Stock/Accounts/light-dark captures; `kpi_strip_widget.dart` uses `errorContainer` as `accentColor`. |
| UX-13 | P2 | Settings tiles are large enough that all five categories do not fit at the minimum size. Profile stretches ordinary fields across nearly the full workspace and repeats its heading; Security sits in a large empty area. Backup labels the live database `app_database.db` instead of the actual `liaqat_store.db`. | Use a compact settings list/detail layout and a bounded form width; align save actions consistently. Show the actual current database name and an understandable backup status. Keep backup/security behavior untouched. | Settings captures, lower-page captures; settings screen/profile/backup/security files. |
| UX-14 | P3 | Generic empty-state messages (`No Data`) and large icons consume space without explaining the next useful action. A single-record state can feel unfinished because empty history areas remain prominent. | Use contextual messages and a useful existing action. Make secondary empty regions compact; retain consistent loading/error/empty layouts. | Sales recent history, stock history panel, archive captures. |

## Screen-by-screen assessment

| Area | What works | Main UI/UX change |
| --- | --- | --- |
| PIN login/recovery/setup | Focused form and familiar PIN/recovery fields; errors/lockout are visible. | Consistent error/help positioning, clear offline recovery guidance and Urdu readability. Avoid decorative depth around an otherwise simple task. |
| Sales | Search, products, cart, total and checkout are recognizably grouped. Checkout remains prominent. | Rebalance grid/cart at minimum width; combine redundant top bars; reduce the visual weight of recent history; clarify selection and payment readiness. |
| Items | A real table supports scanning and inline row actions. | Stable active navigation, aligned toolbar/table and readable bilingual rows; deliberate column widths. |
| Categories | Department/category/detail hierarchy is visible. | Improve empty branches, selected-state distinction and width allocation; retain all hierarchy actions. |
| Units | Category grouping and conversion information are available. | Rename unit actions correctly; align conversion rows; reduce repeated large cards without crowding script text. |
| Customers | Search, balances, ledger access and archive distinction are present. | Reclaim list height; flatten rows; unify toolbar/KPI/search structure; correct ledger responsive overflow. |
| Suppliers | Same basic account workflow makes learning easier. | Match customer presentation and feedback; localize remaining English labels; correct overflow and deletion wording. |
| Stock | Useful summaries, filters, selection and history exist. | Prioritize inventory rows, readable full amounts and accessible actions; remove misleading presentation of placeholders. |
| Purchase | Product selection and bill building are distinct. | Shared Sales/Purchase workspace structure; compact item rows, aligned panel edges and clearer supplier/bill metadata grouping. |
| Cash | In/out direction and payment mode are understandable. | Clear global location, localized dates/filter labels, compact consistent transaction rows and modal feedback. |
| Settings dashboard | Categories are recognizable. | Replace oversized tiles with compact navigation that exposes all categories. |
| Shop profile | Logical fields and a clear save action. | Bounded width, quieter logo treatment, one heading and consistent save placement. |
| Backup | Current/Recent/Options sections are distinguishable. | Correct database label, precise supported-action copy and clearer destructive restore wording. |
| Receipt format | Options are grouped. | Compact labeled rows and a readable preview using the existing receipt renderer, without changing receipt output rules. |
| Preferences | Language/theme/security options are grouped. | Consistent density, readable Urdu labels and an obvious persistence state. |
| Security | PIN-change fields form a focused task. | Bound the form width and align the same modal/form feedback patterns used in authentication. |
| Ledger/archive/export surfaces | Detailed tables and separate archived views exist. | Keep overlay sizes within the actual hosting pane; consistent close/filter/export locations; honest loading/error/empty feedback. |

## Visual hierarchy and accessibility

The correct first focal point for a cashier is product search and the current bill; for account management it is the record list and selected balance. Currently the brand block, top bars and colored summaries often dominate. Use size/weight, alignment and grouping before adding color or depth.

Keep visible focus indicators, keyboard shortcuts, readable disabled states and explicit labels for icon actions. Check the final designs with keyboard-only traversal, enlarged text, long bilingual names, both writing directions, both themes and the actual minimum client area. Sample screenshots alone do not prove accessible names, screen-reader behavior or conformance. A contrast measurement and semantic-control audit should be a UI phase exit gate; no broad contrast-pass claim is made here.

One measured failure: the light-mode Stock Expired value uses RGB `255,218,214` on `241,245,236`, approximately **1.17:1** contrast. This is below both the 3:1 large-text and 4.5:1 normal-text thresholds. [Pixel sample](ui-ux-audit/contrast-sample.json), [WCAG contrast guidance](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html). This sample supports UX-12; it does not imply that every other text color was measured.

What should be retained: familiar domain vocabulary, search-first workflows, persistent navigation, dedicated bill/ledger details, prominent financial totals, existing reversible confirmations and shortcut support. Business functionality does not need a redesign to solve these layout issues.

## The three requested styles

These are visual styles, not complete UX theories.

**Neumorphism:** controls appear softly raised from or pressed into a similarly colored surface, using paired light/dark shadows. It feels quiet and tactile. Without additional signifiers it can make control boundaries and states difficult to distinguish. Use sparingly; a whole POS in this style would make hierarchy and contrast harder to maintain. [NN/g explanation](https://www.nngroup.com/articles/skeuomorphism/)

**Skeuomorphism:** digital controls imitate physical objects or materials, such as a calculator key or paper receipt. Familiar metaphors can help recognition; elaborate textures and realistic decoration also occupy attention and space. A recognizable receipt metaphor is useful, but a textured desk-like interface would compound the current clutter. [NN/g explanation](https://www.nngroup.com/articles/skeuomorphism/)

**Claymorphism:** rounded, inflated forms look like soft clay, often with pastel colors and inner/outer shadows. It is friendly and expressive. It suits limited illustration or onboarding decoration better than dense financial tables and repetitive transaction controls. [Original design explanation by Michał Malewicz](https://hype4.academy/articles/design/claymorphism-in-user-interfaces)

The atlas contains simple side-by-side style illustrations. My recommendation for this POS is restrained Material-like desktop design: clear controls, neutral surfaces, thin separators, limited shadows, compact working rows and deliberate space between groups. Completely flat elements still need obvious clickability and state changes. [NN/g guidance](https://www.nngroup.com/articles/flat-design-best-practices/)

## Proposed UI/UX phases

1. **Layout and typography specification:** define the workspace grid, navigation hierarchy, English/Urdu type roles, compact desktop controls, color/feedback roles and modal structure. Make an annotated Sales/Accounts prototype before rolling these decisions across the application.
2. **Shared shell and responsive foundation:** align page headings, tabs, gutters and toolbar structure; introduce compact/constrained navigation; repair ledger overflow and full-value summary display. Preserve navigation destinations and shortcuts.
3. **Sales and Purchase workspaces:** rebalance selection/bill regions, improve inline fields and checkout readiness, reduce empty secondary regions and unify bill-building presentation.
4. **Management screens:** apply the same structure to Items/Categories/Units, Customers/Suppliers, Stock/Cash and ledger/archive/detail surfaces. Improve scanning and record density without shrinking Urdu into unreadability.
5. **Dialogs, feedback and settings:** standardize form/confirmation layouts, correct copy/localization, use inline validation and coherent snackbar semantics, and compact settings navigation/forms.
6. **Phase acceptance:** compare before/after screenshots at the same data/size; verify full totals and no overflow, keyboard traversal, enlarged text and both languages/themes. Run the complete existing functional regression suite at the end of each completed phase, with focused checks during implementation.

Acceptance targets: no overflow at the supported minimum size; no truncated financial totals; consistent global/local navigation indication; substantially more visible management records; one clear primary action per task; readable Urdu prose and stable number direction; accurate supported-action feedback; unchanged accounting/schema/PIN/backup/export rules.

## Reproduction and validation

Native capture targets are `test/desktop/ui_ux_audit.dart` and `test/desktop/ui_ux_audit_states.dart`, driven by `test/support/desktop_driver.dart`. Both use the existing temporary desktop fixture. The fixture verifies foreign keys and removes its disposable database. Screenshot collection records layout exceptions as audit findings; a passing capture harness does **not** mean the audited UI has no defects.

The normal `lib/main.dart` Windows build must be restored after running any integration target. Analyzer/freeze verification and native capture outcomes are recorded in [validation.json](ui-ux-audit/validation.json). The full business test suite was not rerun for this documentation/capture-only audit.
