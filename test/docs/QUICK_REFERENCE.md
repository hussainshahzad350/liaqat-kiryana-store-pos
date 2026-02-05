# Quick Reference: Documentation Tests

## Test File Location
`test/docs/repository_audit_tasks_test.dart`

## Quick Commands

### Run All Documentation Tests
```bash
flutter test test/docs/repository_audit_tasks_test.dart
```

### Run with Verbose Output
```bash
flutter test test/docs/repository_audit_tasks_test.dart --reporter expanded
```

### Run with Coverage
```bash
flutter test test/docs/repository_audit_tasks_test.dart --coverage
```

## Test Statistics
- **Total Tests**: 55
- **Test Groups**: 11 (1 main group, 10 subgroups)
- **Target File**: `repository_audit_tasks.md`

## Test Group Summary

| Group | Tests | Focus |
|-------|-------|-------|
| File Existence and Basic Structure | 3 | File exists, has title, has dividers |
| Task 1: Typo Fix Task | 6 | Typo documentation completeness |
| Task 2: Bug Fix Task | 6 | Bug documentation completeness |
| Task 3: Documentation Discrepancy | 5 | README fix documentation |
| Task 4: Test Improvement Task | 6 | Test improvement documentation |
| Document Quality and Completeness | 8 | Consistent structure and formatting |
| Content Accuracy and Technical Details | 6 | Technical accuracy verification |
| Task Priority and Organization | 2 | Logical ordering and self-containment |
| Edge Cases and Validation | 7 | Encoding, formatting, consistency |
| Regression and Negative Cases | 6 | Prevent common issues |

## What Gets Tested

### ✓ Structure
- File exists and is readable
- Main title present
- Section dividers (---) present
- All 4 tasks numbered correctly
- Headers follow consistent format

### ✓ Content
- Each task has Title, Why, Scope, Acceptance criteria
- Specific files and paths mentioned
- Technical details accurate
- Code references properly formatted

### ✓ Quality
- Markdown syntax correct
- Backticks around code elements
- No TODO/FIXME markers
- No placeholder text
- Balanced bold markers
- Consistent line endings

### ✓ Semantics
- Tasks don't overlap in scope
- Acceptance criteria are measurable
- Technical solutions are actionable
- Impact is explained

## Common Test Patterns

### Pattern 1: Content Check
```dart
test('description', () {
  expect(content.contains('expected text'), true,
      reason: 'Explanation of why this matters');
});
```

### Pattern 2: Section Extraction
```dart
test('description', () {
  final taskSection = _extractTaskSection(content, 1);
  expect(taskSection.contains('expected'), true);
});
```

### Pattern 3: Count Validation
```dart
test('description', () {
  final count = pattern.allMatches(content).length;
  expect(count, equals(4));
});
```

## Interpreting Test Results

### All Tests Pass ✓
Your documentation is complete, accurate, and follows best practices.

### File Existence Tests Fail ✗
- Check that `repository_audit_tasks.md` exists in repository root
- Verify file permissions allow reading

### Structure Tests Fail ✗
- Verify all 4 tasks have section headers: `## 1)`, `## 2)`, `## 3)`, `## 4)`
- Check that section dividers `---` separate tasks
- Ensure main title exists: `# Repository Issue Tasks`

### Content Tests Fail ✗
- Verify each task has all required sections: Title, Why, Scope, Acceptance criteria
- Check that specific files are mentioned (e.g., `lib/main.dart`)
- Ensure technical terms are present (e.g., `Product.fromMap`, `SQLite`)

### Quality Tests Fail ✗
- Check markdown formatting: balanced bold markers (`**text**`)
- Verify code elements use backticks: `` `code` ``
- Remove any TODO or FIXME markers
- Ensure file paths are formatted: `` `lib/path/to/file.dart` ``

### Negative Tests Fail ✗
- Task scopes are overlapping - make each task more distinct
- TODO/placeholder text found - finalize all content
- Duplicate headers found - ensure each section header is unique

## Helper Script

Use the provided helper script for a better experience:
```bash
chmod +x test/docs/run_tests.sh
./test/docs/run_tests.sh
```

The script:
- Checks Flutter installation
- Runs `flutter pub get`
- Executes tests with expanded reporter
- Shows colored success/failure output

## Integration with CI/CD

### GitHub Actions
```yaml
name: Documentation Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test test/docs/
```

### GitLab CI
```yaml
test:docs:
  script:
    - flutter pub get
    - flutter test test/docs/
```

## Troubleshooting

### Issue: "Flutter not found"
**Solution**: Install Flutter or add to PATH
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### Issue: "File not found: repository_audit_tasks.md"
**Solution**: Run tests from repository root
```bash
cd /path/to/repository
flutter test test/docs/repository_audit_tasks_test.dart
```

### Issue: "Encoding issues"
**Solution**: Ensure file is UTF-8 encoded
```bash
file -i repository_audit_tasks.md
```

### Issue: "Tests timeout"
**Solution**: Increase timeout
```bash
flutter test --timeout=60s test/docs/
```

## Related Files

- `test/docs/repository_audit_tasks_test.dart` - Main test file (575 lines)
- `test/docs/README.md` - Comprehensive documentation
- `test/docs/TEST_SUMMARY.md` - Detailed test breakdown
- `test/docs/run_tests.sh` - Helper script
- `/repository_audit_tasks.md` - File being tested

## Best Practices

1. **Run tests before committing documentation changes**
2. **Use expanded reporter to see all test names**
3. **Read failure reasons carefully** - they explain what's wrong
4. **Keep documentation in sync with code**
5. **Update tests when adding new tasks**

## Performance

Typical test execution time: **< 1 second**
- Fast: No network calls, no database operations
- Pure file reading and string validation
- Suitable for pre-commit hooks

## Test Coverage Philosophy

These tests ensure documentation quality through:
1. **Structural validation** - File and section structure
2. **Content validation** - Required information present
3. **Quality validation** - Formatting and consistency
4. **Semantic validation** - Logical and meaningful content
5. **Regression prevention** - Catch common mistakes

---

**Quick Start**: Just run `flutter test test/docs/repository_audit_tasks_test.dart` from the repository root!