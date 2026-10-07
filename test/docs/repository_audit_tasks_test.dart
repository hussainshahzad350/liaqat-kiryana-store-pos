import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/source_audit.dart';

void main() {
  test('production libraries are reachable from the shipping entry point', () {
    final candidates = auditSources(Directory.current)['candidates']
        as List<Map<String, Object>>;
    expect(candidates, isEmpty);
  });
  test('graph follows package, relative, conditional, export and part edges',
      () {
    final root = Directory.systemTemp.createTempSync('source_audit_');
    addTearDown(() => root.deleteSync(recursive: true));
    void write(String path, String content) {
      final file = File('${root.path}/$path');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    write('lib/main.dart', "import 'package:liaqat_store/a.dart';");
    write('lib/a.dart', "export 'b.dart' if (dart.library.io) 'c.dart';");
    write('lib/b.dart', "part 'd.dart';");
    write('lib/c.dart', 'class C {}');
    write('lib/d.dart', 'part of b;');
    write('lib/unused.dart', 'class Unused {}');
    write(
        'test/use_test.dart', "import '../lib/unused.dart'; Unused? example;");
    final report = auditSources(root);
    expect(report['productionReachableFiles'], 5);
    final candidates = report['candidates'] as List<Map<String, Object>>;
    expect(candidates, hasLength(1));
    expect(candidates.single['path'], 'lib/unused.dart');
    expect(candidates.single['harnessReachable'], true);
    final symbol = (candidates.single['symbols'] as List).single as Map;
    expect(symbol['references'], ['test/use_test.dart']);
  });
}
