# Unused-code cleanup

The user requested removal of code kept only for potential future work. This
supersedes the earlier Phase 5 decision to retain 16 unwired libraries.

The cleanup removed those 16 libraries and purchase_models.dart, which became
unreachable after unused purchase query methods were removed. These cover unused
constants, stock entities, dashboard/invoice-item repositories, maintenance helpers,
unwired models and InfoItem/AppActionButton/AppDataTable/AppFormDialog.
Their only widget callers were the removed prototype gallery and component tests.

For methods in surviving libraries, Dart AST parsing identified declarations,
then exact-name searches across lib/, test/ and tool/ checked callers and tear-offs.
Overrides and operators were excluded. Two passes removed 95 methods/getters,
including obsolete repository reports/CRUD helpers, unused KPI wrappers, RTL helpers
and state accessors. Active financial operations and database migrations retain
existing behavior; this is source cleanup without schema/data changes. An AST
comparison against the snapshot confirms all 3,574 retained methods, constructors
and top-level functions have unchanged code. The member inventory is recorded in
build/verification/cleanup-members.json.

All pre-cleanup source, tests, tools and docs are preserved with hashes in the
local ignored build/cleanup-review/snapshot/. Tests for removed components were
removed; financial, stock, backup, auth, localization and active-screen tests remain.

The source audit now fails on any production library unreachable from lib/main.dart
or any duplicate screen declaration. There is no future-use retention manifest.

```powershell
dart run tool/source_audit.dart
```

The import graph is conservative, including conditional imports and parts. It
checks libraries rather than proving every public member is called. Analyzer
checks private unused members. Neither command deletes code automatically.

Native tests now reside in test/desktop/ and use an explicit Flutter integration
driver. Only VM tests use the _test.dart discovery suffix, so flutter test does
not accidentally launch native suites. CI uses the same driver and serial gates.
Old baseline logs live under build/verification/history/; historical phase results
are retained in docs/history/RESTRUCTURE_BASELINE.md.
