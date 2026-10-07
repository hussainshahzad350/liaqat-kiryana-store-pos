# Backup and recovery

In Settings → Backup, Create backup calls SettingsRepository.createManualBackup.
SQLite `VACUUM INTO` produces a standalone snapshot including committed WAL data.
Manual files are named `manual_backup_<timestamp>_<microseconds>.db` alongside the
active database. The default retention keeps five recognized manual/automatic
backup files. Copy a retained snapshot to separate storage to preserve it beyond
local retention; do not copy only the active `.db` while it has uncheckpointed WAL.

A database snapshot contains store rows, not OS secure-storage credentials,
SharedPreferences preferences, printer setup or externally referenced image files.
Keep the PIN recovery code separately and account for those settings/files when
moving a store. A synthetic test backup does not verify a particular physical
printer or the provenance of an installed database.

Restore in Settings asks for confirmation. The repository checks integrity,
schema version and required tables before replacement. It stages a pre-restore
rollback copy, closes/reopens the database and cleans temporary files. Successful
restores refresh settings/state through the existing controller flow. An invalid,
newer-version or incompatible snapshot must leave current data intact.

Before a real restore, retain a known current backup and identify the intended
snapshot. After restore, check shop identity, catalog, recent transactions, account
balances and stock history. Do not edit rows or invent balance repairs if these
checks disagree; use the read-only diagnosis workflow on a captured copy.

```powershell
python test/support/capture_store_copy.py <source.db> <private-output-directory>
flutter test test/integration/existing_store_copy_test.dart --no-pub --dart-define=STORE_COPY_PATH=<captured.db>
```

The capture script uses SQLite backup to include WAL writes. The test reads the
captured source without writing, opens/restores only a disposable copy, verifies
the source checksum and writes local diagnostics. No supplied path means an
explicit skip. Private snapshots must stay outside version control.

Login locks after five invalid PIN attempts. Forgot PIN uses the saved recovery
code and creates a replacement PIN/recovery code; the previous code stops working.
Recovery and logout/re-login are covered by the disposable desktop harness.
Backup restoration does not bypass or reset PIN authentication.

The earlier populated-real-store and physical-printer waivers remain explicit.
Phase 5's generated large-volume copy verifies release transactions and complete
backup/restore row equality; it is not a captured customer store.
