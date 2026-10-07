# Historical schema fixtures

These SQL files freeze the table/index creation statements from
`lib/core/database/database_helper.dart` at these Git commits:

| Version | Commit | Statements, excluding version pragma |
| --- | --- | --- |
| 1 | `8d41e2150253dc134b2e7cb6e42eac216ecce95b` | 39 |
| 2 | `a9cd83845c543ce50add1d4151c2094c7e8aaf54` | 40 |
| 3 | `f3f9912a515ecebb12bbcb330d1c1e4d79739b8d` | 43 |
| 4 | `b410d1b02213eba00826b82ed9889293add59d58` | 46 |

Statements retain source order and definitions. Each file appends its historical
`user_version`. Tests run these files on disposable databases and seed rows
using the intersection of historical columns and the fresh sample data.
They do not execute historical Dart code or depend on Git at test time.

The version-1 schema already includes `cash_ledger.payment_mode`. Its original
`onOpen` attempted the same addition and swallowed duplicate-column errors.
The additional opened-version-1 fixture reproduces the resulting column state.

These are historical schemas with synthetic records, not copies of customer
store databases. Tests compare all pre-existing row fields across upgrade,
check identity backfills, integrity, foreign keys and repeated open, and verify
that restore leaves the source unchanged. Real-store-copy checks remain required.
