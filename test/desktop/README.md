# Native desktop tests

The canonical aggregate is desktop_smoke.dart, registering the existing 38
English/Urdu native workflow, keyboard, CRUD, receipt and layout scenarios.

Run from the repository root:

```powershell
flutter drive --debug --dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false --driver test/support/desktop_driver.dart --target test/desktop/desktop_smoke.dart -d windows --no-pub
flutter build windows --debug --target lib/main.dart --no-pub
```

Feature files can be used as focused driver targets.
`ui_ux_foundation.dart` verifies shell/rail presentation with keyboard and Sales
states; `ui_ux_workspaces.dart` verifies Sales/Purchase presentation, purchase
posting and minimum-window cart screenshots. These targets use the same driver
and disposable fixtures. Restore the normal `lib/main.dart` build afterwards.

Native files omit the
_test.dart suffix so the ordinary VM test command does not discover them.
The driver uses IntegrationTestWidgetsFlutterBinding through Flutter's supported
integration_test driver; no root integration_test/ folder is needed.

Each scenario owns a disposable SQLite path and memory credentials. Test windows
restore focus for real keyboard traversal. Physical printing and validation on a
populated real-store copy remain outside this automated matrix.

See [test instructions](../README.md) and [release verification](../../docs/RELEASE.md).
