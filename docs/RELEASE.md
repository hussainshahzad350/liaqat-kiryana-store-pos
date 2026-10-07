# Release verification

The shipping target is `lib/main.dart`. Build the normal application with:

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
dart run tool/source_audit.dart
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --no-pub
flutter test --no-pub
flutter drive --debug --dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false --driver test/support/desktop_driver.dart --target test/desktop/desktop_smoke.dart -d windows --no-pub
./tool/verify_release.ps1
```

Run these runtime/build targets serially to avoid SQLite native-asset locks.
Use focused tests while implementing; run the full suite once at phase exit.
If this Windows host loses Flutter listener temp directories, set command-local
TEMP and TMP to `build/verification/temp` before VM tests. Restore ordinary environment
settings afterward; do not alter the SDK.

The desktop integration runner in the verified SDK forces debug builds. Release
verification therefore compiles `tool/release_smoke.dart` as a separate Windows
AOT executable. It opens a generated isolated database, installs memory preferences
and secure credentials, creates a large dataset and opens an independent copy.
The source hash must remain unchanged. It invokes the actual PIN/search/cart/cash
checkout widget callbacks and verifies persisted outcomes; this is not a native
mouse/keyboard automation test. English/Urdu native keyboard and visual coverage
is supplied by the debug desktop matrix.

The AOT harness then verifies cash/bank/credit/mixed sales and rejected repeat
reversals, customer/supplier payments, purchase/reversal, stock adjustment, cash
in/out and complete backup/restore row equality. Runtime checks throw exceptions;
they do not rely on assertions that are removed in release mode. It records seven
warm samples for repository/page/backup operations, plus native startup and
checkout timings. See PERFORMANCE.md for definitions and observed results.

`verify_release.ps1` enforces a bounded process timeout and checks the JSON result.
Its finally block rebuilds `lib/main.dart` in release mode even if the verification
fails. Do not package the harness binary: use the restored `runner/Release/`
folder, including DLLs and `data/`, rather than copying only the executable.
Current logs are retained under build/verification/; historical baseline logs
are under build/verification/history/. Release-smoke.json remains under
build/cleanup-phase5-review/. CI runs the same
source-audit and release commands, but local completion does not claim a hosted run.

Before distribution, retain a database backup/recovery code and perform an
operator smoke check on the target machine. Physical printer validation and a
populated real-store copy were waived during this plan; the generated dataset
provides volume evidence without satisfying those two checks. Secure-storage
plugin persistence, other OS targets and production hardware performance are not
established by the memory-backed harness.
