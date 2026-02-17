# Repository Issue Tasks (Targeted Fix Proposals)

## 1) Typo Fix Task
**Title:** Rename `stock_overveiw` to `stock_overview` across folder and imports.

**Why:** The feature directory is misspelled as `stock_overveiw`, and that typo appears in multiple imports. This hurts discoverability and increases the chance of inconsistent naming in future modules.

**Scope:**
- Rename folder: `lib/bloc/stock/stock_overveiw/` → `lib/bloc/stock/stock_overview/`
- Update imports in `lib/main.dart`, `lib/screens/stock/stock_screen.dart`, and related bloc files.

**Acceptance criteria:**
- No import paths include `stock_overveiw`.
- `flutter analyze` passes.

---

## 2) Bug Fix Task
**Title:** Make `Product.fromMap` resilient to SQLite numeric type variance (`int`/`double`).

**Why:** `Product.fromMap` currently casts several DB numeric fields directly as `int` (`min_stock_alert`, `avg_cost_price`, `sale_price`). SQLite frequently returns `num` values as either `int` or `double` depending on query/driver behavior. Direct `as int` casts can throw runtime `TypeError` when values come back as `double` (e.g., `10.0`). The `fromMap` method needs to handle both integer and floating-point numeric types safely.

**Scope:**
- Replace unsafe casts with `num` coercion using `toInt()` method: `(map['field'] as num?)?.toInt() ?? fallback`.
- Add regression tests for maps where these fields are doubles.

**Acceptance criteria:**
- Parsing product maps with `10` and `10.0` both succeeds.
- Unit tests cover both integer and floating numeric input paths.

---

## 3) Documentation Discrepancy Task
**Title:** Update README architecture section to match actual state management implementation.

**Why:** README says “No BLoC: Kept simple for maintainability,” but the repository contains a substantial BLoC structure (`lib/bloc/...`). This mismatch can mislead contributors and new maintainers.

**Scope:**
- Correct the “Technology Stack / State Management” section.
- Replace contradictory statements with current architecture (BLoC + screen state where applicable).

**Acceptance criteria:**
- README architecture claims align with existing code organization.
- New contributors can infer current patterns without contradiction.

---

## 4) Test Improvement Task
**Title:** Replace the `HomeScreen` placeholder test with a behavior-level widget test using dependency injection.

**Why:** Current test only checks `expect(HomeScreen, isNotNull)`, which does not validate rendering, loading, or user-visible behavior. It provides almost no regression protection.

**Scope:**
- Refactor `HomeScreen` to allow repository/service injection in tests.
- Add widget tests that verify loading state and at least one rendered dashboard value.
- Keep a smoke test only as an additional minimal check, not the main test.

**Acceptance criteria:**
- Home screen test fails if key UI behavior breaks.
- Tests avoid hitting real database dependencies.
