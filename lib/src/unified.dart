import 'myers.dart';

class Hunk {
  Hunk({
    required this.oldStart,
    required this.oldCount,
    required this.newStart,
    required this.newCount,
    required this.lines,
  });

  final int oldStart;
  final int oldCount;
  final int newStart;
  final int newCount;
  final List<String> lines;
}

List<Hunk> buildHunks(List<Edit> edits, {int context = 3}) {
  final changed = <int>[
    for (var i = 0; i < edits.length; i++)
      if (edits[i].kind != EditKind.equal) i,
  ];
  if (changed.isEmpty) return const [];

  final ranges = <List<int>>[];
  var start = changed.first;
  var end = changed.first;
  for (final index in changed.skip(1)) {
    if (index - end - 1 <= 2 * context) {
      end = index;
    } else {
      ranges.add([start, end]);
      start = index;
      end = index;
    }
  }
  ranges.add([start, end]);

  final oldBefore = List<int>.filled(edits.length + 1, 0);
  final newBefore = List<int>.filled(edits.length + 1, 0);
  for (var i = 0; i < edits.length; i++) {
    oldBefore[i + 1] = oldBefore[i] + (edits[i].kind == EditKind.insert ? 0 : 1);
    newBefore[i + 1] = newBefore[i] + (edits[i].kind == EditKind.delete ? 0 : 1);
  }

  final hunks = <Hunk>[];
  for (final range in ranges) {
    final from = (range[0] - context).clamp(0, edits.length);
    final to = (range[1] + context + 1).clamp(0, edits.length);
    final lines = <String>[];
    for (var i = from; i < to; i++) {
      final prefix = switch (edits[i].kind) {
        EditKind.equal => ' ',
        EditKind.insert => '+',
        EditKind.delete => '-',
      };
      lines.add('$prefix${edits[i].line}');
    }
    final oldCount = oldBefore[to] - oldBefore[from];
    final newCount = newBefore[to] - newBefore[from];
    hunks.add(Hunk(
      oldStart: oldCount == 0 ? oldBefore[from] : oldBefore[from] + 1,
      oldCount: oldCount,
      newStart: newCount == 0 ? newBefore[from] : newBefore[from] + 1,
      newCount: newCount,
      lines: lines,
    ));
  }
  return hunks;
}

String _range(int start, int count) => count == 1 ? '$start' : '$start,$count';

String formatUnified(
  List<String> a,
  List<String> b, {
  String oldName = 'a',
  String newName = 'b',
  int context = 3,
}) {
  final hunks = buildHunks(diffLines(a, b), context: context);
  if (hunks.isEmpty) return '';
  final out = StringBuffer()
    ..writeln('--- $oldName')
    ..writeln('+++ $newName');
  for (final hunk in hunks) {
    out.writeln(
      '@@ -${_range(hunk.oldStart, hunk.oldCount)} '
      '+${_range(hunk.newStart, hunk.newCount)} @@',
    );
    hunk.lines.forEach(out.writeln);
  }
  return out.toString();
}
