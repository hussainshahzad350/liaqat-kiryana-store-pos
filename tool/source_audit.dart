import 'dart:convert';
import 'dart:io';

/// Conservative import graph audit. Findings require review, never auto-delete.
Map<String, Object> auditSources(Directory root) {
  final sources = <String, String>{};
  for (final folder in ['lib', 'test', 'tool']) {
    final directory = Directory('${root.path}/$folder');
    if (!directory.existsSync()) continue;
    for (final file in directory.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final relative = file.absolute.uri.path
          .substring(root.absolute.uri.path.length)
          .replaceAll('\\', '/');
      sources[relative] = file.readAsStringSync();
    }
  }
  final edges = <String, Set<String>>{};
  final imports = RegExp(r'\b(?:import|export|part)\s+([^;]+);');
  final quotes = RegExp(r'''['"]([^'"]+)['"]''');
  for (final entry in sources.entries) {
    final dependencies = <String>{};
    for (final directive in imports.allMatches(entry.value)) {
      for (final match in quotes.allMatches(directive[1]!)) {
        final uri = match[1]!;
        String target;
        if (uri.startsWith('package:liaqat_store/')) {
          target = 'lib/${uri.substring('package:liaqat_store/'.length)}';
        } else if (uri.contains(':')) {
          continue;
        } else {
          target = Uri.parse(entry.key).resolve(uri).path;
        }
        if (sources.containsKey(target)) dependencies.add(target);
      }
    }
    edges[entry.key] = dependencies;
  }
  Set<String> reachable(Iterable<String> starts) {
    final queue = starts.toList();
    final seen = <String>{};
    while (queue.isNotEmpty) {
      final next = queue.removeLast();
      if (seen.add(next)) queue.addAll(edges[next] ?? {});
    }
    return seen;
  }

  final active = reachable(['lib/main.dart']);
  final harness = reachable(sources.keys.where((f) => !f.startsWith('lib/')));
  final candidates = <Map<String, Object>>[];
  for (final entry in sources.entries) {
    if (!entry.key.startsWith('lib/') || active.contains(entry.key)) continue;
    final symbols = RegExp(r'\b(?:class|enum|mixin)\s+(\w+)')
        .allMatches(entry.value)
        .map((m) => m[1]!)
        .where((s) => !s.startsWith('_'));
    candidates.add({
      'path': entry.key,
      'harnessReachable': harness.contains(entry.key),
      'symbols': [
        for (final symbol in symbols)
          {
            'name': symbol,
            'references': sources.entries
                .where((other) =>
                    other.key != entry.key &&
                    RegExp('\\b$symbol\\b').hasMatch(other.value))
                .map((other) => other.key)
                .toList()
              ..sort(),
          }
      ],
    });
  }
  candidates
      .sort((a, b) => (a['path'] as String).compareTo(b['path'] as String));
  final screens = <String, List<String>>{};
  for (final entry in sources.entries.where((e) => e.key.startsWith('lib/'))) {
    for (final declaration
        in RegExp(r'\bclass\s+(\w+Screen)\s+extends').allMatches(entry.value)) {
      screens.putIfAbsent(declaration[1]!, () => []).add(entry.key);
    }
  }
  return {
    'productionReachableFiles': active.length,
    'dartFiles': sources.length,
    'candidates': candidates,
    'duplicateScreens': {
      for (final screen in screens.entries)
        if (screen.value.length > 1) screen.key: screen.value
    },
  };
}

/// Fails when unused production libraries or duplicate screens are introduced.
void main(List<String> args) {
  final report = auditSources(Directory.current);
  final candidates = report['candidates'] as List<Map<String, Object>>;
  final paths = candidates.map((c) => c['path'] as String).toSet();
  final drift = [
    ...paths.map((p) => 'Unused production library: $p'),
  ];
  drift.addAll((report['duplicateScreens'] as Map)
      .keys
      .map((name) => 'Duplicate screen declaration: $name'));
  final output =
      File(args.isEmpty ? 'build/verification/source-audit.json' : args.first);
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report)}\n');
  stdout.writeln(
      '${paths.length} unused libraries; ${drift.length} audit issues.');
  for (final message in drift) {
    stderr.writeln(message);
  }
  if (drift.isNotEmpty) exitCode = 1;
}
