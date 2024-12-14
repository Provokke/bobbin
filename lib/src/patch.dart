import 'myers.dart';
import 'unified.dart';

class PatchException implements Exception {
  PatchException(this.message);

  final String message;

  @override
  String toString() => 'PatchException: $message';
}

final _hunkHeader = RegExp(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@');

List<Hunk> parseUnified(String patch) {
  final hunks = <Hunk>[];
  Hunk? current;
  var header = <int>[];
  var lines = <String>[];

  void finish() {
    final open = current;
    if (open == null) return;
    hunks.add(Hunk(
      oldStart: header[0],
      oldCount: header[1],
      newStart: header[2],
      newCount: header[3],
      lines: lines,
    ));
    current = null;
  }

  for (final line in splitLines(patch)) {
    final match = _hunkHeader.firstMatch(line);
    if (match != null) {
      finish();
      header = [
        int.parse(match.group(1)!),
        int.parse(match.group(2) ?? '1'),
        int.parse(match.group(3)!),
        int.parse(match.group(4) ?? '1'),
      ];
      lines = <String>[];
      current = Hunk(oldStart: 0, oldCount: 0, newStart: 0, newCount: 0, lines: lines);
    } else if (current != null) {
      if (line.startsWith('\\')) continue;
      if (line.isEmpty || ' +-'.contains(line[0])) {
        lines.add(line.isEmpty ? ' ' : line);
      } else {
        throw PatchException('unexpected line in hunk: $line');
      }
    }
  }
  finish();
  return hunks;
}

List<String> applyHunks(List<String> original, List<Hunk> hunks) {
  final result = <String>[];
  var cursor = 0;
  for (final hunk in hunks) {
    final start = hunk.oldCount == 0 ? hunk.oldStart : hunk.oldStart - 1;
    if (start < cursor || start > original.length) {
      throw PatchException('hunk at line ${hunk.oldStart} is out of order or out of range');
    }
    result.addAll(original.sublist(cursor, start));
    cursor = start;
    for (final line in hunk.lines) {
      final text = line.substring(1);
      switch (line[0]) {
        case ' ':
        case '-':
          if (cursor >= original.length || original[cursor] != text) {
            throw PatchException(
              'hunk at line ${hunk.oldStart} does not match input at line ${cursor + 1}',
            );
          }
          if (line[0] == ' ') result.add(text);
          cursor++;
        case '+':
          result.add(text);
      }
    }
  }
  result.addAll(original.sublist(cursor));
  return result;
}

String applyPatch(String original, String patch) {
  final lines = applyHunks(splitLines(original), parseUnified(patch));
  return lines.isEmpty ? '' : '${lines.join('\n')}\n';
}
