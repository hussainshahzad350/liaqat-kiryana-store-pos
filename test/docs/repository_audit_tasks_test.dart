import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  group('Repository Audit Tasks Documentation', () {
    late String auditTasksContent;
    late File auditTasksFile;

    setUp(() async {
      auditTasksFile = File('repository_audit_tasks.md');
      auditTasksContent = await auditTasksFile.readAsString();
    });

    group('File Existence and Basic Structure', () {
      test('repository_audit_tasks.md exists and is not empty', () {
        expect(auditTasksFile.existsSync(), true,
            reason: 'repository_audit_tasks.md should exist in the repository root');
        expect(auditTasksContent.isNotEmpty, true,
            reason: 'repository_audit_tasks.md should have content');
      });

      test('file has a proper title', () {
        expect(auditTasksContent.contains('# Repository Issue Tasks'),
            true,
            reason: 'Document should have a clear main title');
      });

      test('file contains section dividers', () {
        final dividerCount = '---'.allMatches(auditTasksContent).length;
        expect(dividerCount, greaterThanOrEqualTo(3),
            reason: 'Document should use section dividers (---) to separate tasks');
      });
    });

    group('Task 1: Typo Fix Task', () {
      test('contains Typo Fix Task section', () {
        expect(auditTasksContent.contains('## 1) Typo Fix Task'), true,
            reason: 'Document should include Task 1: Typo Fix');
      });

      test('has a clear title for the typo fix', () {
        expect(auditTasksContent.contains('**Title:**'), true);
        expect(
            auditTasksContent.contains(
                'Rename `stock_overveiw` to `stock_overview`'),
            true,
            reason: 'Task 1 should clearly state the typo being fixed');
      });

      test('includes rationale (Why section)', () {
        final task1Section = _extractTaskSection(auditTasksContent, 1);
        expect(task1Section.contains('**Why:**'), true,
            reason: 'Task 1 should explain why the fix is needed');
        expect(task1Section.contains('misspelled'), true,
            reason: 'Task 1 should mention the typo issue');
      });

      test('defines scope of changes', () {
        final task1Section = _extractTaskSection(auditTasksContent, 1);
        expect(task1Section.contains('**Scope:**'), true);
        expect(
            task1Section.contains('lib/bloc/stock/stock_overveiw/'),
            true,
            reason: 'Task 1 should specify the folder to rename');
        expect(task1Section.contains('lib/bloc/stock/stock_overview/'), true,
            reason: 'Task 1 should specify the correct folder name');
      });

      test('includes acceptance criteria', () {
        final task1Section = _extractTaskSection(auditTasksContent, 1);
        expect(task1Section.contains('**Acceptance criteria:**'), true);
        expect(task1Section.contains('flutter analyze'), true,
            reason: 'Task 1 acceptance criteria should mention flutter analyze');
        expect(task1Section.contains('No import paths include'), true,
            reason:
                'Task 1 acceptance criteria should verify no typo remains in imports');
      });

      test('references specific files affected', () {
        final task1Section = _extractTaskSection(auditTasksContent, 1);
        expect(task1Section.contains('lib/main.dart'), true,
            reason: 'Task 1 should mention main.dart as an affected file');
        expect(
            task1Section.contains('lib/screens/stock/stock_screen.dart'),
            true,
            reason: 'Task 1 should mention stock_screen.dart as an affected file');
      });
    });

    group('Task 2: Bug Fix Task', () {
      test('contains Bug Fix Task section', () {
        expect(auditTasksContent.contains('## 2) Bug Fix Task'), true,
            reason: 'Document should include Task 2: Bug Fix');
      });

      test('identifies the Product.fromMap issue', () {
        final task2Section = _extractTaskSection(auditTasksContent, 2);
        expect(task2Section.contains('Product.fromMap'), true,
            reason: 'Task 2 should mention Product.fromMap method');
        expect(task2Section.contains('SQLite'), true,
            reason: 'Task 2 should mention SQLite as the database');
      });

      test('explains the type casting problem', () {
        final task2Section = _extractTaskSection(auditTasksContent, 2);
        expect(task2Section.contains('as int'), true,
            reason: 'Task 2 should mention the problematic cast pattern');
        expect(task2Section.contains('TypeError'), true,
            reason: 'Task 2 should mention TypeError as the error');
        expect(task2Section.contains('double'), true,
            reason: 'Task 2 should explain the int/double variance issue');
      });

      test('specifies fields that need fixing', () {
        final task2Section = _extractTaskSection(auditTasksContent, 2);
        expect(task2Section.contains('min_stock_alert'), true,
            reason: 'Task 2 should list min_stock_alert as a field to fix');
        expect(task2Section.contains('avg_cost_price'), true,
            reason: 'Task 2 should list avg_cost_price as a field to fix');
        expect(task2Section.contains('sale_price'), true,
            reason: 'Task 2 should list sale_price as a field to fix');
      });

      test('provides solution approach', () {
        final task2Section = _extractTaskSection(auditTasksContent, 2);
        expect(task2Section.contains('num'), true,
            reason: 'Task 2 should mention using num type');
        expect(task2Section.contains('toInt()'), true,
            reason: 'Task 2 should suggest toInt() conversion');
      });

      test('includes test requirements in acceptance criteria', () {
        final task2Section = _extractTaskSection(auditTasksContent, 2);
        expect(task2Section.contains('Unit tests'), true,
            reason: 'Task 2 should require unit tests');
        expect(task2Section.contains('10') && task2Section.contains('10.0'),
            true,
            reason: 'Task 2 should verify both int and double parsing');
      });

      test('mentions regression testing', () {
        final task2Section = _extractTaskSection(auditTasksContent, 2);
        expect(task2Section.contains('regression'), true,
            reason: 'Task 2 should require regression tests');
      });
    });

    group('Task 3: Documentation Discrepancy Task', () {
      test('contains Documentation Discrepancy Task section', () {
        expect(
            auditTasksContent.contains('## 3) Documentation Discrepancy Task'),
            true,
            reason: 'Document should include Task 3: Documentation Fix');
      });

      test('identifies README inconsistency', () {
        final task3Section = _extractTaskSection(auditTasksContent, 3);
        expect(task3Section.contains('README'), true,
            reason: 'Task 3 should mention README file');
        expect(task3Section.contains('No BLoC'), true,
            reason: 'Task 3 should quote the incorrect README statement');
        expect(task3Section.contains('lib/bloc/'), true,
            reason: 'Task 3 should reference the actual bloc directory');
      });

      test('explains impact of documentation mismatch', () {
        final task3Section = _extractTaskSection(auditTasksContent, 3);
        expect(task3Section.contains('mislead'), true,
            reason: 'Task 3 should explain how wrong docs mislead developers');
        expect(
            task3Section.contains('contributors') ||
                task3Section.contains('maintainers'),
            true,
            reason: 'Task 3 should mention impact on team members');
      });

      test('targets specific README section', () {
        final task3Section = _extractTaskSection(auditTasksContent, 3);
        expect(
            task3Section.contains('Technology Stack') ||
                task3Section.contains('State Management'),
            true,
            reason: 'Task 3 should specify which README section needs updating');
      });

      test('requires alignment between docs and code', () {
        final task3Section = _extractTaskSection(auditTasksContent, 3);
        expect(
            task3Section.contains('align') ||
                task3Section.contains('match') ||
                task3Section.contains('current'),
            true,
            reason:
                'Task 3 acceptance criteria should verify docs match actual implementation');
      });
    });

    group('Task 4: Test Improvement Task', () {
      test('contains Test Improvement Task section', () {
        expect(auditTasksContent.contains('## 4) Test Improvement Task'), true,
            reason: 'Document should include Task 4: Test Improvement');
      });

      test('identifies inadequate test coverage', () {
        final task4Section = _extractTaskSection(auditTasksContent, 4);
        expect(task4Section.contains('HomeScreen'), true,
            reason: 'Task 4 should mention HomeScreen');
        expect(task4Section.contains('placeholder'), true,
            reason: 'Task 4 should identify the test as a placeholder');
        expect(task4Section.contains('isNotNull'), true,
            reason: 'Task 4 should mention the inadequate isNotNull check');
      });

      test('explains why current test is insufficient', () {
        final task4Section = _extractTaskSection(auditTasksContent, 4);
        expect(
            task4Section.contains('does not validate') ||
                task4Section.contains('no regression'),
            true,
            reason: 'Task 4 should explain test inadequacy');
      });

      test('requires dependency injection for testability', () {
        final task4Section = _extractTaskSection(auditTasksContent, 4);
        expect(task4Section.contains('injection'), true,
            reason: 'Task 4 should mention dependency injection pattern');
      });

      test('specifies widget test improvements', () {
        final task4Section = _extractTaskSection(auditTasksContent, 4);
        expect(task4Section.contains('widget test'), true,
            reason: 'Task 4 should require widget tests');
        expect(task4Section.contains('loading state'), true,
            reason: 'Task 4 should test loading states');
        expect(
            task4Section.contains('rendered') ||
                task4Section.contains('dashboard'),
            true,
            reason: 'Task 4 should test UI rendering');
      });

      test('ensures tests avoid real database dependencies', () {
        final task4Section = _extractTaskSection(auditTasksContent, 4);
        expect(task4Section.contains('avoid'), true);
        expect(
            task4Section.contains('database') ||
                task4Section.contains('dependencies'),
            true,
            reason: 'Task 4 should require tests to avoid real database');
      });

      test('requires tests that fail when behavior breaks', () {
        final task4Section = _extractTaskSection(auditTasksContent, 4);
        final acceptanceCriteria =
            task4Section.split('**Acceptance criteria:**')[1];
        expect(acceptanceCriteria.contains('fail'), true,
            reason:
                'Task 4 acceptance criteria should verify tests detect regressions');
      });
    });

    group('Document Quality and Completeness', () {
      test('all tasks have titles', () {
        final titleMatches =
            RegExp(r'\*\*Title:\*\*').allMatches(auditTasksContent);
        expect(titleMatches.length, equals(4),
            reason: 'Each of the 4 tasks should have a Title section');
      });

      test('all tasks have why/rationale sections', () {
        final whyMatches =
            RegExp(r'\*\*Why:\*\*').allMatches(auditTasksContent);
        expect(whyMatches.length, equals(4),
            reason: 'Each of the 4 tasks should explain why it is needed');
      });

      test('all tasks have scope definitions', () {
        final scopeMatches =
            RegExp(r'\*\*Scope:\*\*').allMatches(auditTasksContent);
        expect(scopeMatches.length, equals(4),
            reason: 'Each of the 4 tasks should define its scope');
      });

      test('all tasks have acceptance criteria', () {
        final acceptanceMatches =
            RegExp(r'\*\*Acceptance criteria:\*\*')
                .allMatches(auditTasksContent);
        expect(acceptanceMatches.length, equals(4),
            reason:
                'Each of the 4 tasks should have clear acceptance criteria');
      });

      test('tasks are properly numbered from 1 to 4', () {
        expect(auditTasksContent.contains('## 1)'), true);
        expect(auditTasksContent.contains('## 2)'), true);
        expect(auditTasksContent.contains('## 3)'), true);
        expect(auditTasksContent.contains('## 4)'), true);
      });

      test('consistent markdown formatting for headers', () {
        final headerPattern = RegExp(r'^## \d\) .+ Task$', multiLine: true);
        final headerMatches = headerPattern.allMatches(auditTasksContent);
        expect(headerMatches.length, equals(4),
            reason: 'All task headers should follow consistent format');
      });

      test('uses proper markdown code formatting', () {
        // Check for inline code (backticks)
        expect(auditTasksContent.contains('`'), true,
            reason: 'Document should use backticks for code/filenames');

        // Verify specific code elements are properly formatted
        expect(auditTasksContent.contains('`stock_overveiw`'), true,
            reason: 'Folder names should be in backticks');
        expect(auditTasksContent.contains('`Product.fromMap`'), true,
            reason: 'Method names should be in backticks');
        expect(auditTasksContent.contains('`flutter analyze`'), true,
            reason: 'Commands should be in backticks');
      });

      test('file paths use consistent format', () {
        // Verify paths are in code format
        final pathPattern = RegExp(r'`lib/[^`]+`');
        final pathMatches = pathPattern.allMatches(auditTasksContent);
        expect(pathMatches.length, greaterThan(3),
            reason: 'File paths should be consistently formatted with backticks');
      });
    });

    group('Content Accuracy and Technical Details', () {
      test('references existing Flutter/Dart files', () {
        expect(auditTasksContent.contains('lib/'), true,
            reason: 'Should reference Flutter lib directory');
        expect(auditTasksContent.contains('.dart'), true,
            reason: 'Should reference Dart source files');
      });

      test('mentions appropriate Flutter commands', () {
        expect(auditTasksContent.contains('flutter analyze'), true,
            reason: 'Should use Flutter static analysis command');
      });

      test('SQLite type system is correctly described', () {
        final task2Section = _extractTaskSection(auditTasksContent, 2);
        expect(task2Section.contains('int') && task2Section.contains('double'),
            true,
            reason: 'Should explain SQLite numeric type variance');
      });

      test('technical solutions are actionable', () {
        final task2Section = _extractTaskSection(auditTasksContent, 2);
        // Should provide code pattern/example
        expect(
            task2Section.contains('(map[') ||
                task2Section.contains('?.toInt()'),
            true,
            reason: 'Should provide concrete code patterns');
      });

      test('BLoC architecture is correctly referenced', () {
        expect(auditTasksContent.contains('BLoC'), true,
            reason: 'Should reference BLoC pattern correctly');
        expect(auditTasksContent.contains('bloc'), true,
            reason: 'Should reference bloc directory');
      });
    });

    group('Task Priority and Organization', () {
      test('tasks are logically ordered', () {
        // Extract task positions
        final typoPos = auditTasksContent.indexOf('## 1) Typo Fix Task');
        final bugPos = auditTasksContent.indexOf('## 2) Bug Fix Task');
        final docPos =
            auditTasksContent.indexOf('## 3) Documentation Discrepancy Task');
        final testPos =
            auditTasksContent.indexOf('## 4) Test Improvement Task');

        expect(typoPos, lessThan(bugPos),
            reason: 'Typo fix should come before bug fix');
        expect(bugPos, lessThan(docPos),
            reason: 'Bug fix should come before documentation fix');
        expect(docPos, lessThan(testPos),
            reason: 'Documentation fix should come before test improvement');
      });

      test('each task is self-contained', () {
        for (int i = 1; i <= 4; i++) {
          final section = _extractTaskSection(auditTasksContent, i);
          expect(section.contains('**Title:**'), true,
              reason: 'Task $i should be self-contained with title');
          expect(section.contains('**Why:**'), true,
              reason: 'Task $i should be self-contained with rationale');
          expect(section.contains('**Scope:**'), true,
              reason: 'Task $i should be self-contained with scope');
          expect(section.contains('**Acceptance criteria:**'), true,
              reason: 'Task $i should be self-contained with criteria');
        }
      });
    });

    group('Edge Cases and Validation', () {
      test('file encoding is UTF-8 compatible', () {
        // Should handle special characters without issues
        expect(() => auditTasksContent.codeUnits, returnsNormally,
            reason: 'File should be properly encoded');
      });

      test('line endings are consistent', () {
        // Check that file doesn't mix line endings
        final hasUnixEndings = auditTasksContent.contains('\n');

        // File should use one style consistently (preferably Unix)
        expect(hasUnixEndings, true,
            reason: 'File should use Unix-style line endings');
      });

      test('no trailing whitespace on key lines', () {
        final lines = auditTasksContent.split('\n');
        final headerLines =
            lines.where((line) => line.startsWith('##')).toList();

        for (final line in headerLines) {
          expect(line.trimRight(), equals(line),
              reason: 'Header lines should not have trailing whitespace');
        }
      });

      test('markdown lists use consistent formatting', () {
        final listItemPattern = RegExp(r'^- .+$', multiLine: true);
        final listItems = listItemPattern.allMatches(auditTasksContent);
        expect(listItems.length, greaterThan(8),
            reason: 'Document should use markdown lists for scopes and criteria');
      });

      test('no broken markdown formatting', () {
        // Check for common markdown issues
        expect(auditTasksContent.contains('**'), true,
            reason: 'Should use bold formatting');

        // Count opening and closing bold markers should be even
        final boldMarkers = '**'.allMatches(auditTasksContent).length;
        expect(boldMarkers % 2, equals(0),
            reason: 'All bold markers should be properly closed');
      });

      test('references to code elements are consistently formatted', () {
        // Method calls should be in backticks
        expect(auditTasksContent.contains('`fromMap`'), true);
        expect(auditTasksContent.contains('`toInt()`'), true);

        // Variables/fields in backticks
        expect(auditTasksContent.contains('`min_stock_alert`'), true);
      });
    });

    group('Regression and Negative Cases', () {
      test('document does not contain TODO or FIXME markers', () {
        expect(auditTasksContent.toUpperCase().contains('TODO'), false,
            reason: 'Finalized documentation should not have TODO markers');
        expect(auditTasksContent.toUpperCase().contains('FIXME'), false,
            reason: 'Finalized documentation should not have FIXME markers');
      });

      test('document does not have placeholder text', () {
        expect(auditTasksContent.contains('[TODO]'), false);
        expect(auditTasksContent.contains('[PLACEHOLDER]'), false);
        expect(auditTasksContent.contains('Lorem ipsum'), false);
      });

      test('no duplicate section headers', () {
        final headers = <String>[];
        final headerPattern = RegExp(r'^## \d\) .+$', multiLine: true);

        for (final match in headerPattern.allMatches(auditTasksContent)) {
          final header = match.group(0)!;
          expect(headers.contains(header), false,
              reason: 'Section header "$header" should be unique');
          headers.add(header);
        }
      });

      test('acceptance criteria are measurable', () {
        for (int i = 1; i <= 4; i++) {
          final section = _extractTaskSection(auditTasksContent, i);
          final acceptanceSection =
              section.split('**Acceptance criteria:**').last;

          // Should contain verifiable conditions
          final hasMeasurableCriteria =
              acceptanceSection.contains('passes') ||
                  acceptanceSection.contains('succeeds') ||
                  acceptanceSection.contains('includes') ||
                  acceptanceSection.contains('No ') ||
                  acceptanceSection.contains('fails') ||
                  acceptanceSection.contains('verify') ||
                  acceptanceSection.contains('align');

          expect(hasMeasurableCriteria, true,
              reason:
                  'Task $i acceptance criteria should be measurable/verifiable');
        }
      });

      test('file size is reasonable for documentation', () {
        final fileSize = auditTasksFile.lengthSync();
        expect(fileSize, greaterThan(1000),
            reason: 'Documentation should have substantial content');
        expect(fileSize, lessThan(50000),
            reason: 'Documentation should be concise and focused');
      });

      test('task descriptions do not overlap in scope', () {
        // Each task should address different aspects
        final task1 = _extractTaskSection(auditTasksContent, 1);
        final task2 = _extractTaskSection(auditTasksContent, 2);
        final task3 = _extractTaskSection(auditTasksContent, 3);
        final task4 = _extractTaskSection(auditTasksContent, 4);

        // Task 1 is about typos, should not mention bug fixes
        expect(task1.contains('TypeError'), false,
            reason: 'Task 1 should focus on typo, not type errors');

        // Task 2 is about bugs, should not mention documentation
        expect(task2.contains('README'), false,
            reason: 'Task 2 should focus on bugs, not documentation');

        // Task 3 is about docs, should not mention tests
        expect(task3.toLowerCase().contains('unit test'), false,
            reason: 'Task 3 should focus on docs, not tests');

        // Each task should have distinct focus
        expect(task1.contains('overveiw'), true,
            reason: 'Task 1 should focus on typo');
        expect(task2.contains('fromMap'), true,
            reason: 'Task 2 should focus on Product.fromMap');
        expect(task3.contains('README'), true,
            reason: 'Task 3 should focus on README');
        expect(task4.contains('HomeScreen'), true,
            reason: 'Task 4 should focus on HomeScreen tests');
      });
    });
  });
}

/// Helper function to extract a specific task section from the document
String _extractTaskSection(String content, int taskNumber) {
  final taskStart = content.indexOf('## $taskNumber)');
  if (taskStart == -1) return '';

  // Find the next task or end of document
  final nextTaskNumber = taskNumber + 1;
  final nextTaskStart = content.indexOf('## $nextTaskNumber)');

  if (nextTaskStart == -1) {
    // This is the last task
    return content.substring(taskStart);
  } else {
    return content.substring(taskStart, nextTaskStart);
  }
}