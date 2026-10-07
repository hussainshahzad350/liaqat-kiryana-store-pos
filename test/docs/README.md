# Source inventory tests

repository_audit_tasks_test.dart checks that all production libraries are reachable
from lib/main.dart and verifies package/relative/conditional/part graph traversal.
Run from the repository root:

```powershell
flutter test test/docs/repository_audit_tasks_test.dart --no-pub
```

The old document-content assertions and their historical summary are obsolete.
Current suite instructions live in ../README.md.
