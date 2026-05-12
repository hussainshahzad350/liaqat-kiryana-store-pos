# Repository Issue Tasks

This document lists four actionable tasks discovered during a repository audit.
Each task is intentionally scoped, measurable, and mapped to concrete files and
commands so contributors can execute and verify the fixes quickly.

---

## 1) Typo Fix Task

**Title:** Rename `stock_overveiw` to `stock_overview`

**Why:** A misspelled folder name (`stock_overveiw`) is confusing, easy to
misread in imports, and increases maintenance risk for contributors.

**Scope:**
- Rename `lib/bloc/stock/stock_overveiw/` to `lib/bloc/stock/stock_overview/`.
- Update imports in `lib/main.dart`.
- Update imports in `lib/screens/stock/stock_screen.dart`.
- Update any remaining references in `lib/` and tests.

**Acceptance criteria:**
- `flutter analyze` passes after the rename.
- No import paths include `stock_overveiw`.
- Build succeeds and includes all stock overview BLoC wiring.
- Verify navigation to stock screen still works.

---

## 2) Bug Fix Task

**Title:** Fix numeric casting in `Product.fromMap` for SQLite values

**Why:** `Product.fromMap` currently assumes strict `as int` shapes in some
paths, but SQLite may return numeric values as `int` or `double`; this can
raise `TypeError` at runtime and break mapping logic.

**Scope:**
- Update `Product.fromMap` conversion logic in `lib/models/product_model.dart`.
- Replace fragile direct casts such as `as int` for numeric fields where needed.
- Ensure these fields parse safely: `min_stock_alert`, `avg_cost_price`,
  and `sale_price`.
- Use `num` intermediate casting and `toInt()` only where integer semantics are
  required.

**Acceptance criteria:**
- Mapping handles both `10` and `10.0` without throwing.
- Unit tests include cases for mixed SQLite numeric types.
- regression checks verify no behavior change for valid existing records.
- Verify the final conversion pattern includes robust examples like
  `(map['min_stock_alert'] as num?)?.toInt()`.
- Keep helper references explicit (`Product.fromMap`, `fromMap`, and `toInt()`)
  so implementers can align naming and behavior.

---

## 3) Documentation Discrepancy Task

**Title:** Align README state-management wording with actual BLoC architecture

**Why:** The README currently states "No BLoC" in wording that does not match
the codebase. This can mislead contributors and maintainers about the real
architecture and onboarding expectations.

**Scope:**
- Update README `Technology Stack` / `State Management` section text.
- Replace the inaccurate "No BLoC" statement with current implementation notes.
- Reference the real source layout in `lib/bloc/`.
- Ensure wording matches current code and architecture decisions.

**Acceptance criteria:**
- README text aligns with current implementation.
- Architecture description clearly mentions BLoC usage.
- Contributors can match docs to actual folders without ambiguity.
- Verify no contradictory statements remain in README.

---

## 4) Test Improvement Task

**Title:** Replace HomeScreen placeholder assertions with regression-focused tests

**Why:** Existing HomeScreen test coverage relies on placeholder checks (for
example, only asserting `isNotNull`), which does not validate critical behavior
and provides no regression safety.

**Scope:**
- Improve tests around `HomeScreen` behavior in `test/widget/home_screen_test.dart`.
- Introduce dependency injection where needed to improve testability.
- Expand widget test coverage for loading state, empty state, and dashboard
  rendered content.
- Ensure tests avoid real database dependencies by using mocks/fakes.

**Acceptance criteria:**
- Widget test suite includes meaningful behavior assertions.
- Loading state and dashboard rendering are both verified.
- Tests fail when behavior breaks (not just when widgets are null).
- Regression-focused checks are measurable and reproducible in CI.

