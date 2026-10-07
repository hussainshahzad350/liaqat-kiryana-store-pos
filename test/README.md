# Tests

VM and native desktop tests live under this directory:

| Folder | Purpose |
| --- | --- |
| unit/, bloc/, widget/ | VM logic/state and active UI tests |
| integration/ | VM repository tests on disposable SQLite databases |
| desktop/ | Native Windows workflows, keyboard, layout and receipts |
| support/, fixtures/ | Shared isolated databases, credentials, data and driver |
| docs/ | Live source inventory/graph checks |

From the repository root:

```powershell
flutter test --no-pub
flutter drive --debug --dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false --driver test/support/desktop_driver.dart --target test/desktop/desktop_smoke.dart -d windows --no-pub
flutter build windows --debug --target lib/main.dart --no-pub
```

Run VM tests, native SQLite tests and builds serially. Native files deliberately
use .dart without the _test.dart discovery suffix. Flutter's `test` command selects
native integration mode only for the root integration_test/ directory; the explicit
integration driver lets the native suite live here without a root test directory.
The driver collects results; the define disables Android/XCTest instrumentation
reporting on Windows. The final build restores the ordinary application after
the native harness.

For a focused native run, select a feature target such as
`--target test/desktop/desktop_startup.dart` with the same driver. Test databases
and credentials are isolated before app bootstrap. Source store copies are never
opened for writes. Actual store-copy validation is optional and remains waived.

Logs belong under build/verification/. On Windows hosts with Flutter listener
cleanup issues, set command-local TEMP/TMP to an existing directory under
build/verification/temp/ for the VM run.

See [release verification](../docs/RELEASE.md) for the separate AOT checks.

UI redesign targets use the same driver: `ui_ux_records.dart` checks account/stock
workflows and ordinary minimum layouts; `ui_ux_acceptance.dart` checks populated
record density, all workspaces/settings at 125% text, ledger filters and dialog
validation in both languages and modes. `ui_ux_final.dart` combines the native
smoke suite and acceptance checks. `ui_ux_repairs.dart` reruns checkout, product
CRUD and acceptance after a failure, without repeating unrelated native cases.
Set command-local `UI_AUDIT_SCREENS_ONLY=true` with `ui_ux_audit.dart` to collect
strict matched-fixture screen evidence in `build/ui-ux-redesign-matched/`.

`desktop_mouse_input.dart` verifies mouse-only PIN entry, English/Urdu product
search, quantity arrows, price/discount entry and Cash/Bank Transfer checkout at
the minimum Windows size. It uses disposable databases and captures layouts in
`build/mouse-input-review/`. `widget/mouse_input_test.dart` checks input callbacks,
PIN masking/formatters, cancel, read-only fields and compact keyboard layouts.
