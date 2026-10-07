# Onboarding

1. Install the verified Flutter/Dart SDK and Windows C++ desktop toolchain.
   Confirm `flutter doctor -v` and `flutter devices` expose Windows.
2. Resolve `pubspec.lock` with `flutter pub get --enforce-lockfile`; generate
   localization with `flutter gen-l10n`. `l10n.yaml` requests formatted output.
3. Read ARCHITECTURE.md and the relevant feature map.
   Identify the intended layer before editing; preserve existing uncommitted work.
4. Run the app with `flutter run -d windows`. The shipping app uses installed
   local data and secure credentials. First-use PIN setup produces a recovery code.
   In VS Code, select **POS — Windows (current source)** and press F5. The launch
   configuration pins Windows debug mode, lib/main.dart and the workspace root;
   workspace settings point to the verified C:\src\flutter SDK.
5. Use disposable tests for development: the database fixtures replace the SQLite
   factory path before app bootstrap; preferences and credentials are in-memory.
6. Run focused tests for the touched area, then analyzer/source audit. Run the full
   suite at phase exit and fix discovered failures within the authorized scope.

```powershell
dart run tool/source_audit.dart
flutter analyze --no-pub
flutter test test/widget/remaining_feature_components_test.dart --no-pub
```

Full-suite and release commands are in RELEASE.md. If local Flutter listener
cleanup loses its temporary directory, set command-local TEMP/TMP to a generated
workspace build directory as documented there. Do not alter SDK internals.

`test/widget/home_screen_test.dart` verifies SalesKpiHeader; its historical name
does not imply a live Home screen. Unused future-use APIs have been removed. Add new components when a current
feature needs them. All tests live under test/; see ../test/README.md.
