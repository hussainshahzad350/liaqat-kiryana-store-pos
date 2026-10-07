# Liaqat Kiryana Store POS

A bilingual English/Urdu desktop POS built with Flutter, BLoC/Cubit and SQLite.
The current restructuring work preserves the existing money, stock, ledger and
migration contracts. Windows is the platform with recorded runtime verification;
other platform folders are present but do not establish tested support.

## Working features

- Sales: product/customer search, cart, cash/bank/credit/mixed payments,
  cancellation, receipt printing and PDF export.
- Products: item metadata/archive, department/category hierarchy and base/derived
  units. Product management is reached from Products & Stock.
- Stock/purchases: overview, adjustments, activity history, purchasing and
  purchase cancellation.
- Accounts: customers/suppliers, payments, ledgers, archive and restore.
- Cash ledger: cash in/out, payment-mode/date filters and paging.
- Settings: shop profile, backup/restore, receipt preferences, language/theme,
  PIN setup/change/recovery. Login hosts a persistent application shell.

Reporting, barcode-camera workflows, online sync, FBR integration and messaging
are not established by the current route registry. Earlier README claims about
those features and a `sales`/`sale_items` schema were stale.

## Get started

The verified toolchain is Flutter **3.44.4**, Dart **3.12.2**, Windows with Visual
Studio's Desktop development with C++ workload. Use the locked dependencies:

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter run -d windows
```

The app creates schema version **5** in `liaqat_store.db` under the database
factory's desktop data path. First launch presents PIN setup; save the generated
recovery code. Use the Settings UI for subsequent PIN and receipt configuration.
See [onboarding](docs/ONBOARDING.md) and [backup/recovery](docs/BACKUP_RECOVERY.md).

## Code and verification

`lib/main.dart` owns bootstrap and app-wide dependencies; `AppShell` owns routes
and feature lifetimes. Widgets compose features; BLoCs/Cubits/controllers retain
existing state ownership; repositories own persistence. Money values are integer
paisa. See [architecture](docs/ARCHITECTURE.md) and
[UI contracts](docs/UI_SYSTEM.md) before changing an implementation.

```powershell
dart run tool/source_audit.dart
flutter analyze --no-pub
flutter test --no-pub
flutter drive --debug --dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false --driver test/support/desktop_driver.dart --target test/desktop/desktop_smoke.dart -d windows --no-pub
flutter build windows --release --no-pub
```

Run native SQLite targets, VM tests and builds serially. Use focused tests during
individual changes and the full suite at phase exit. The source audit lists
unused production libraries and duplicate screens; it never deletes code.
For measured release-mode workflows and synthetic-volume performance, follow
[release verification](docs/RELEASE.md) and [performance](docs/PERFORMANCE.md).

[Restructure plan](docs/RESTRUCTURE_PLAN.md), [baseline evidence](docs/BASELINE.md)
and [cleanup decisions](docs/CLEANUP_AUDIT.md) record completed gates, repairs and
limitations. Physical printing and a populated real-store copy retain the earlier
explicit waiver. Synthetic databases do not establish real-store provenance.

All five UI/UX redesign phases are complete. The
[implementation plan](docs/UI_UX_IMPLEMENTATION_PLAN.md) and
[completion record](docs/UI_UX_COMPLETION.md) link the matched screenshots and
verification results. The [native audit](docs/UI_UX_AUDIT.md) preserves the original
assessment; the [functional freeze boundary](docs/UI_UX_FREEZE.md) still applies.

Read [architecture](docs/ARCHITECTURE.md) before editing protected code.
Schema, money/ledger calculations and cross-layer changes require their
own explicit scope. Do not replace the locked core with a new database or state
management framework as part of a presentation cleanup.
