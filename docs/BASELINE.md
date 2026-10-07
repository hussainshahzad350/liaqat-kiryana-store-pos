# Verification record

The restructuring phases 0–5 are complete. Detailed historical results are in
[the archived phase record](history/RESTRUCTURE_BASELINE.md).

## Current cleanup

The post-plan cleanup removes unused production APIs and consolidates verification:

- 17 unused libraries removed, including the 16 formerly retained future-use libraries.
- 95 methods/getters removed from surviving libraries after declaration/caller checks.
- Unused imports and the obsolete receipt database field removed.
- Native scenarios moved from root integration_test/ into test/desktop/.
- Three redundant phase-specific native aggregators removed; desktop_smoke.dart registers the existing feature scenarios.
- The unused-component gallery and its dedicated tests removed along with those components.
- 235 baseline logs moved into build/verification/history/; new logs go into build/verification/.
- Complete pre-cleanup source snapshot and hashes kept locally in build/cleanup-review/.

The complete VM suite passed: **490 tests, one optional store-copy check skipped**,
119 seconds. Analyzer reports no issues, and the source audit reports zero unused
libraries/duplicate screens. AST comparison confirms 3,574 retained methods,
constructors and functions unchanged, with 95 removed members.

The full relocated Windows matrix passed: **38 scenarios plus setup/teardown**
(40 runner checks), 8 minutes 11 seconds, through the integration driver.
The normal application rebuilt in 38.8 seconds.
An optional native-instrumentation reporting warning was found; the Windows
command now disables that channel while retaining driver result collection.
The focused four-scenario startup run passes with that option and no plugin
reporting warning. The ordinary application rebuilt afterward in 20.1 seconds.
Final analyzer: no issues. Formatting: 261 files, zero changes. CI YAML and the
release PowerShell script parse; staged/unstaged whitespace checks pass.

Historical counts include tests of components that have now been removed; they are not the
current suite size. No database migration or stored-data conversion was made.

The populated real-store-copy and physical-printer checks remain waived and
unverified. Synthetic volume evidence is documented in [PERFORMANCE.md](PERFORMANCE.md).

## Commands

See [test/README.md](../test/README.md) for VM/native commands and
[RELEASE.md](RELEASE.md) for AOT release verification. Runtime/build targets run
serially. Generated logs and test outputs belong under ignored build/verification/.

## Clean local launch — 2026-10-04

Flutter clean removed all prior build output, .dart_tool (including the active
SQLite database) and generated platform caches. VS Code now explicitly launches
lib/main.dart on Windows with the verified SDK rather than relying on entry-point
inference. The active database, manual/emergency database backups and prior review
evidence were preserved under .local/reset-backups/20261004-154328/ before cleanup.
That directory is ignored and excluded from analysis; it is not app runtime data.
The app-specific Windows preferences/secure-storage files were absent at reset.
Fresh-launch logs are written under build/verification/fresh-*.log.
Locked dependencies and localization regeneration pass. The clean Windows debug
build of lib/main.dart passes (129.9 seconds); analyzer reports no issues. The
active database remains absent until the next application launch creates it.
