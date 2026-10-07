# UI system

Production screens use AppUiTheme through AppFeatureTheme (and scoped Sales theme),
with persisted palette, brightness and language owned by ThemeProvider. AppUiTheme
uses the existing AppThemes fonts and Material color roles. It does not change
financial calculations, routes or state ownership.

The authorized redesign is tracked in [UI_UX_IMPLEMENTATION_PLAN.md](UI_UX_IMPLEMENTATION_PLAN.md).
Its first phase replaces tinted surface roles with neutral light/dark surfaces,
removes shared card elevation, uses a neutral start-aligned shell header and
reduces expanded navigation to 224 px. Below 1200 px client width navigation
uses a 64 px rail without changing SidebarCubit state. Rail actions have localized
tooltips and selected semantics; Cash Ledger has a direct entry. The Product
workspace highlights Products & Stock while that entry still opens Stock.
Sidebar width changes immediately to avoid overflow while expanded labels mount.

## Shared components

| Component | Current use |
| --- | --- |
| AppSearchCard | Search fields and existing selection callbacks |
| AppStateView | Loading, empty, recoverable error and retry presentation |
| AppFeatureTheme | Shared feature theme boundary |
| AppManagementTabs | Product/account management tabs |
| AppPaneViewport | Bounded scrolling panes |
| AppHeader, AppShell, AppNavigationSidebar | Shell, navigation and shortcuts |

The unused AppActionButton, AppDataTable and AppFormDialog prototypes and their
gallery were removed. Features use themed Material buttons, DataTable and dialogs.
Create a shared component when an actual feature needs it rather than retaining
an unused prototype.

## Tokens and behavior

Use semantic AppTokens aliases for spacing and shape: relatedGap 8,
contentGap/surfacePadding 16, sectionGap 24, controlMinHeight 48,
controlRadius 8, surfaceRadius 12, modalRadius 16 and focusBorderWidth 2.
Use titleMedium/bodyMedium/labelLarge/bodySmall from the current theme.

Use paired Material colors: primary/onPrimary for actions, surface/onSurface
for content, primaryContainer/onPrimaryContainer for selection and error pairs
for destructive actions. Palette contrast tests cover the scoped theme; they
are not an accessibility certification of every screen.

Urdu uses NooriNastaleeq with compact line-height 1.2 and zero letter spacing.
Rows and controls must grow or scroll when text wraps. Use directional padding
and start/end alignment. Keep amounts and numeric columns readable within RTL.
All user-visible labels, tooltips, validation and errors come from localization.

## Layout and keyboard

AppLayout retains the 1024×720 minimum outer desktop window. Window chrome can
reduce content space, so use actual pane constraints and LayoutBuilder. Desktop
width thresholds remain 1366, 1920 and 2560 for legacy panes. Sales now allocates
42% of its available workspace (after the shared panel gap) to the cart, bounded
to 360–600 px. Its summary and actions share one row; recent sales starts collapsed
with a visible count and reveals the same print/cancel actions on expansion.
The product grid aligns with its search field, and Sales/Purchase use 16 px outer
gutters and a 16 px panel gap. Purchase uses bounded panels and compact invoice,
date and notes fields; its events, validation and save behavior are unchanged.
Settings uses two columns below 900 available pixels and three from 900 upward.
Dialogs constrain width with pixels and scroll vertically. Tables scroll where
necessary; control heights are minimums rather than clipping limits.

Tab/Shift+Tab traverses enabled controls. Enter/Space activates the focused action;
Escape cancels dialogs where supported. Disabled and busy actions have null
callbacks. Sales shortcuts remain owned by its existing feature handlers. Preserve
focus scope boundaries so selection/search and cart actions remain usable.

## Verification

```powershell
flutter test --no-pub test/unit/app_ui_theme_test.dart test/unit/app_layout_test.dart test/widget/app_state_view_test.dart test/widget/remaining_feature_components_test.dart
flutter drive --debug --dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false --driver test/support/desktop_driver.dart --target test/desktop/desktop_smoke.dart -d windows --no-pub
flutter build windows --debug --target lib/main.dart --no-pub
```

Tests cover English/Urdu, light/dark modes, retries and native minimum-window
workflows. Run native/build targets serially. See [test instructions](../test/README.md)
for fixture isolation and [verification record](BASELINE.md) for current results.

## Records, dialogs and settings

Account summaries use compact neutral cards, and record rows have no shadow.
Ledger date/type/search filters wrap within their pane. Inventory has the primary
height; Recent Activities expands on request. Financial summaries show full values.
Stock table columns fill their surface when space permits and retain horizontal
scrolling when required.

Settings categories use compact list tiles. Forms and save actions share a bounded
width; sections use neutral surfaces. PIN inputs grow with text instead of clipping
to a fixed height. Unit/payment/date labels are localized, supplier deactivation
copy describes preserved transactions, and unsupported stock operations show their
existing unavailable status. Dialogs use the shared modal title/content theme.
Item-name validation remains beside its field and clears when edited; retain async
lookup futures across presentation rebuilds. Errors use the existing localized
mapper, and leaving a workspace clears its transient messages.

## Checkout payment selection

Show the final payable total beside compact Cash and Bank Transfer choices.
Selecting a choice fills the existing tender controllers with the exact final
total, clears the other tenders, and enables Proceed through the existing
validation and InvoiceProcessed flow. Require a choice before full payment.
Keep split payments, credit and tendered cash/change under Other payment options;
their calculations and credit-limit checks remain unchanged. Wrap choices for
narrow layouts and enlarged text, and mirror the layout in Urdu.

## Mouse input

The app footer offers an on-screen keyboard for the focused writable field.
Click a field, open the keyboard, and apply the edited value. English, Urdu and
numeric layouts support typing with the mouse; PIN previews remain obscured.
Cancel leaves the original field untouched. Apply uses the existing field input
formatters and change callback, preserving validation and calculations.

Cart quantity fields include compact increase/decrease arrows. These use the
existing debounced quantity update and prevent stepping to zero. Physical
keyboard entry remains available. Native mouse-only checkout coverage lives in
`test/desktop/desktop_mouse_input.dart`; focused input tests cover small layouts,
English/Urdu, light/dark themes, masked PINs and read-only fields.
