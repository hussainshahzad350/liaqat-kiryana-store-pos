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
