# Documentation Tests

This directory contains tests for documentation files in the repository.

## Test Files

### `repository_audit_tasks_test.dart`
Comprehensive tests for the `repository_audit_tasks.md` documentation file.

**Test Coverage:**
- File existence and basic structure validation
- Content validation for all 4 tasks (Typo Fix, Bug Fix, Documentation, Test Improvement)
- Document quality checks (formatting, completeness, consistency)
- Technical accuracy verification
- Task organization and priority validation
- Edge cases and regression prevention
- Markdown formatting validation

**Total Test Count:** 60+ comprehensive tests organized into 9 test groups

## Running the Tests

### Run all documentation tests:
```bash
flutter test test/docs/
```

### Run specific test file:
```bash
flutter test test/docs/repository_audit_tasks_test.dart
```

### Run with verbose output:
```bash
flutter test test/docs/repository_audit_tasks_test.dart --reporter expanded
```

## Test Groups

1. **File Existence and Basic Structure** (3 tests)
   - Validates file exists and has proper structure
   - Checks for main title and section dividers

2. **Task 1: Typo Fix Task** (6 tests)
   - Validates task structure and content
   - Checks for title, rationale, scope, and acceptance criteria
   - Verifies specific files and folders are mentioned

3. **Task 2: Bug Fix Task** (6 tests)
   - Validates Product.fromMap bug documentation
   - Checks problem explanation and solution approach
   - Verifies affected fields are listed
   - Ensures test requirements are included

4. **Task 3: Documentation Discrepancy Task** (5 tests)
   - Validates README inconsistency documentation
   - Checks problem identification and impact
   - Verifies specific sections are targeted

5. **Task 4: Test Improvement Task** (6 tests)
   - Validates HomeScreen test improvement documentation
   - Checks for dependency injection requirements
   - Verifies widget test improvements are specified

6. **Document Quality and Completeness** (8 tests)
   - Ensures all tasks have required sections
   - Validates consistent markdown formatting
   - Checks code element formatting

7. **Content Accuracy and Technical Details** (6 tests)
   - Validates technical accuracy of references
   - Checks Flutter/Dart specific content
   - Verifies SQLite type system description

8. **Task Priority and Organization** (2 tests)
   - Validates logical task ordering
   - Ensures tasks are self-contained

9. **Edge Cases and Validation** (7 tests)
   - File encoding checks
   - Line ending consistency
   - Markdown formatting validation
   - Code reference consistency

10. **Regression and Negative Cases** (6 tests)
    - Checks for TODO/FIXME markers
    - Validates no placeholder text
    - Ensures unique section headers
    - Verifies measurable acceptance criteria
    - Validates reasonable file size
    - Ensures non-overlapping task scopes

## Test Philosophy

These tests follow Flutter/Dart testing best practices:
- **Comprehensive Coverage**: Tests cover structural, semantic, and quality aspects
- **Clear Assertions**: Each test has descriptive names and reason messages
- **Edge Case Handling**: Tests include boundary conditions and negative cases
- **Regression Prevention**: Tests catch common documentation issues
- **Maintainable**: Tests are organized into logical groups for easy maintenance

## Expected Results

All tests should pass when `repository_audit_tasks.md` is properly structured with:
- 4 distinct tasks with proper numbering
- Each task having Title, Why, Scope, and Acceptance criteria sections
- Consistent markdown formatting
- Technical accuracy in code references
- Proper use of backticks for code elements
- No placeholder or TODO markers

## Adding New Tests

When adding new documentation tests:
1. Follow the existing test group structure
2. Use descriptive test names starting with lowercase
3. Include `reason` parameter in expect() for clarity
4. Group related tests together
5. Test both positive cases (what should be there) and negative cases (what shouldn't be there)

## Related Files

- `/repository_audit_tasks.md` - The documentation file being tested
- `/test/unit/` - Unit tests for business logic
- `/test/widget/` - Widget tests for UI components
- `/test/integration/` - Integration tests for database operations