Liaqat Kiryana Store POS — Project Skill
Project Identity

App name: Liaqat Kiryana Store POS
Target platforms: Windows, Linux, macOS, Android, iOS
Architecture: BLoC/Cubit + SQLite (offline-first) + repository pattern
UI framework: Flutter 3.27+, Material 3, AppTokens design system
Localization: English (LTR) + Urdu (RTL) via AppLocalizations (ARB files)
Long-term roadmap: Multi-tenant SaaS, FBR compliance, WhatsApp receipts, JazzCash/Easypaisa


AI Change Guardrails — ABSOLUTE RULES
These rules are non-negotiable. Violating any of them requires immediate rejection.

One layer per prompt — UI changes never touch BLoC; BLoC changes never touch repositories; repositories never touch the database schema.
No silent renames — Never rename classes, methods, variables, files, or routes unless explicitly instructed.
Database schema is read-only — No column renames, table drops, new columns, or schema redesigns without explicit human instruction.
Money/ledger logic is human-owned — Never modify calculations, debit/credit flows, cancel/reverse logic, stock adjustments, or rounding.
Grep before delete — Before removing any file or class, run a grep to confirm zero active usages exist.
flutter analyze must pass zero errors before any prompt is considered complete.
Additive-only schema changes — Any DB work must only add, never modify or remove.


Gold Standard Reference
The Sales Screen (lib/screens/sales/) is the Gold Standard at 9.8/10. All other screens are audited and refactored against it.
Screen File Structure
lib/screens/{screen_name}/
├── {screen_name}_screen.dart     # 600–800 lines max
├── dialogs/                      # One file per dialog, 150–200 lines each
├── widgets/                      # Reusable components, 100–150 lines each
└── utils/                        # Pure helpers, 50–100 lines each
Quality Score Targets

Minimum acceptable: 8.5/10
Target: 9.5/10
Gold Standard: 9.8/10


Critical Code Patterns
✅ API Preferences (never use the deprecated versions)
Use thisNot this.withValues(alpha: x).withOpacity(x)WidgetStatePropertyMaterialStatePropertytextTheme.ROLE?.copyWith()bare TextStyle(...)context.mountedmountedPopScopeWillPopScopeMoney.tryParse(text) ?? Money.zerotry-catch around Money.fromRupeesString()
✅ Mounted Checks — Required Locations
Always check context.mounted before:

All ScaffoldMessenger calls
All Navigator calls
After every await
In all BLoC listeners
After dialog dismissals

✅ BLoC Failure State Hygiene (double-emit pattern)
After every validation error and every catch block, failure states must immediately re-emit back to a ready state. This matches the SalesBloc pattern and prevents the UI getting stuck.
dart// ✅ CORRECT — double-emit pattern
emit(SomeFailure(message: 'Validation failed'));
emit(const SomeReady());   // immediately re-emit ready

// ❌ WRONG — stuck failure state
emit(SomeFailure(message: 'Validation failed'));
// (nothing follows — UI is now stuck)
✅ Post-Action Cleanup
After any successful state-changing operation (e.g. purchase submission, sale completion):

Clear relevant UI state (cart, form fields)
Trigger downstream refreshes (stock levels, lists)

✅ No Widget References in Cubit State
UI widgets must never be stored in Cubit or BLoC state. Local screen state (StatefulWidget) holds widget references if needed.
✅ Localization — No Hardcoded Strings
Every user-facing string uses AppLocalizations:
dartfinal loc = AppLocalizations.of(context)!;
Text(loc.someKey)   // ✅
Text('Some text')   // ❌
Covers: labels, tooltips, button text, dialog titles, error messages, snackbars.
✅ Error Handling via ErrorHandler
dartfinal err = ErrorHandler.getLocalizedMessage(state.errorMessage, loc);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(err), backgroundColor: colorScheme.error),
);
✅ Debounce Search Inputs

Product/item search: 100ms
Customer search: 300ms
General text search: 200ms

dartTimer? _searchDebounce;
void _onSearch(String query) {
  _searchDebounce?.cancel();
  _searchDebounce = Timer(const Duration(milliseconds: 300), () {
    context.read<MyBloc>().add(SearchChanged(query));
  });
}
Always cancel the timer in dispose().
✅ Dialog Size Constraints — Fixed Pixels Only
dart// ✅ Correct
constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),

// ❌ Wrong
maxWidth: MediaQuery.of(context).size.width * 0.6,
Size guide: small 400–500px, medium 450–550px, large 500–650px.
✅ Responsive Panel Widths — Breakpoint-Based
dartLayoutBuilder(builder: (context, constraints) {
  double panelWidth = constraints.maxWidth >= 2560 ? 600
      : constraints.maxWidth >= 1920 ? 550
      : constraints.maxWidth >= 1366 ? 500
      : 450;
  return Row(children: [
    Expanded(child: leftPanel),
    SizedBox(width: panelWidth, child: rightPanel),
  ]);
});

Urdu / RTL Font Rules

English font: Roboto (standard)
Urdu font: NooriNastaleeq (RTL)
Critical: NooriNastaleeq has tall line-height characteristics. Always set height: 1.2 explicitly in any TextStyle applied to Urdu text to prevent RenderFlex overflows.

dart// ✅ Urdu text style
TextStyle(fontFamily: 'NooriNastaleeq', height: 1.2)

Architecture Rules
Layering (strict top-down, no inversions)
Presentation (BLoC/Cubit + Widgets)
    ↓
Domain (Entities + Repository interfaces)
    ↓
Data (Repository implementations + SQLite)

Repositories must NOT depend on BLoCs (architectural inversion)
Cross-screen communication uses broadcast streams on the repository layer (e.g. stockChanged stream on ItemsRepository)
BLoCs are provided at feature level, not globally, unless truly app-wide

Domain Getters — No Magic Strings
dart// ✅ Domain getter
if (invoice.isCancelled) { }
if (customer.isWalkIn) { }

// ❌ Magic string
if (invoice.status == 'CANCELLED') { }
if (customer.id == 1) { }

Screen Audit Protocol
When auditing a screen, score it across 9 phases and deduct points per anti-pattern:

File structure — modularisation, line counts
State management — BLoC usage, no direct repo calls from UI
Mounted safety — all async paths covered
Localization — zero hardcoded strings
Error handling — ErrorHandler used, no nested ternaries
UI patterns — dialog sizes, font hierarchy, toolbar compactness
Architecture — no cross-layer violations, no Widget in state
Deprecated APIs — WillPopScope, withOpacity, MaterialStateProperty
Post-action hygiene — cart cleared, stock refreshed, failure states reset

Audit and fix are always separate phases. Never audit and refactor in the same prompt.

Refactoring Workflow (Phased)
Each phase = one prompt = one layer. Never combine.
PhaseScopeLayerPre-UI fixesBLoC failure states, post-action cleanupBLoC onlyPhase 1File structure extractionUI structurePhase 2Code quality (mounted, localization, ErrorHandler)UI onlyPhase 3UI/UX patterns (dialogs, fonts, breakpoints)UI onlyPhase 4Architecture (domain getters, stream wiring)Domain/Data
Verification after every phase: flutter analyze must show zero errors.

Current Screen Status (as of last session)
ScreenScoreStatusSales Screen9.8/10 ✅Gold Standard — do not modifyStock Screen~9.3–9.7/10Near complete; side panel feature pendingPurchase Screen3.4/10 ⚠️Full rewrite planned; Phase 1.5 BLoC fixes first
Purchase Screen — Phase 1.5 BLoC Fixes Required Before UI Work
Five fixes (A–E) must be applied to purchase_bloc.dart before the UI rewrite:

Fix A–B: Failure states never reset to ready (missing double-emit)
Fix C: Successful purchase submission does not clear the cart
Fix D: Successful purchase does not refresh stock levels
Fix E: (see session notes for remaining detail)

Known Anti-Patterns in Purchase Screen (do NOT replicate)

BLoC bypassed — direct repository calls from UI
Nested MainLayout causing double sidebar
Missing mounted checks
Deprecated APIs
Non-functional search in dialogs
Hardcoded strings throughout
Raw Map used instead of typed PurchaseItemEntity


Prompt Construction Rules
When writing an AI change prompt, always include:

File path being changed
Layer it belongs to (UI / BLoC / Repository / Domain)
Explicit confirmation that no schema or cross-layer change will occur
Find/replace instructions (exact old string → new string)
Verification step: flutter analyze + relevant grep check
Do's and Don'ts specific to that prompt

Every prompt must be self-contained and copy-pasteable.