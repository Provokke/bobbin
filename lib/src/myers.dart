enum EditKind { equal, insert, delete }

class Edit {
  const Edit(this.kind, this.line);

  final EditKind kind;
  final String line;

  @override
  bool operator ==(Object other) =>
      other is Edit && other.kind == kind && other.line == line;

  @override
  int get hashCode => Object.hash(kind, line);

  @override
  String toString() => '${kind.name}($line)';
}

List<Edit> diffLines(List<String> a, List<String> b) {
  final n = a.length;
  final m = b.length;
  final max = n + m;
  if (max == 0) return const [];
  final offset = max;
  final v = List<int>.filled(2 * max + 2, 0);
  final trace = <List<int>>[];
  var finalD = -1;

  for (var d = 0; d <= max && finalD < 0; d++) {
    trace.add(List<int>.of(v));
    for (var k = -d; k <= d; k += 2) {
      int x;
      if (k == -d || (k != d && v[offset + k - 1] < v[offset + k + 1])) {
        x = v[offset + k + 1];
      } else {
        x = v[offset + k - 1] + 1;
      }
      var y = x - k;
      while (x < n && y < m && a[x] == b[y]) {
        x++;
        y++;
      }
      v[offset + k] = x;
      if (x >= n && y >= m) {
        finalD = d;
        break;
      }
    }
  }

  final edits = <Edit>[];
  var x = n;
  var y = m;
  for (var d = finalD; d > 0; d--) {
    final prev = trace[d];
    final k = x - y;
    int prevK;
    if (k == -d || (k != d && prev[offset + k - 1] < prev[offset + k + 1])) {
      prevK = k + 1;
    } else {
      prevK = k - 1;
    }
    final prevX = prev[offset + prevK];
    final prevY = prevX - prevK;
    while (x > prevX && y > prevY) {
      edits.add(Edit(EditKind.equal, a[x - 1]));
      x--;
      y--;
    }
    if (x == prevX) {
      edits.add(Edit(EditKind.insert, b[y - 1]));
      y--;
    } else {
      edits.add(Edit(EditKind.delete, a[x - 1]));
      x--;
    }
  }
  while (x > 0 && y > 0) {
    edits.add(Edit(EditKind.equal, a[x - 1]));
    x--;
    y--;
  }
  return edits.reversed.toList();
}

List<String> splitLines(String text) {
  if (text.isEmpty) return <String>[];
  final lines = text.split('\n');
  if (lines.last.isEmpty) lines.removeLast();
  return lines;
}
