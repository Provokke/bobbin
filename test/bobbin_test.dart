import 'package:bobbin/bobbin.dart';
import 'package:test/test.dart';

List<String> lines(String s) => s.isEmpty ? [] : s.split('');

List<String> replay(List<Edit> edits, {required bool forNew}) => [
      for (final e in edits)
        if (e.kind == EditKind.equal ||
            e.kind == (forNew ? EditKind.insert : EditKind.delete))
          e.line,
    ];

void main() {
  group('diffLines', () {
    test('identical input is all equal', () {
      final edits = diffLines(['a', 'b'], ['a', 'b']);
      expect(edits.every((e) => e.kind == EditKind.equal), isTrue);
      expect(edits.length, 2);
    });

    test('empty inputs', () {
      expect(diffLines([], []), isEmpty);
      expect(diffLines([], ['x']), [const Edit(EditKind.insert, 'x')]);
      expect(diffLines(['x'], []), [const Edit(EditKind.delete, 'x')]);
    });

    test('classic Myers example has a minimal script', () {
      final a = lines('ABCABBA');
      final b = lines('CBABAC');
      final edits = diffLines(a, b);
      final changes = edits.where((e) => e.kind != EditKind.equal).length;
      expect(changes, 5);
      expect(replay(edits, forNew: false), a);
      expect(replay(edits, forNew: true), b);
    });

    test('reconstructs both sides for varied inputs', () {
      final cases = [
        ['a', 'b', 'c'],
        ['b', 'c', 'd'],
        ['x', 'a', 'b', 'y'],
        ['a', 'a', 'a'],
        ['c', 'b', 'a'],
        <String>[],
      ];
      for (final a in cases) {
        for (final b in cases) {
          final edits = diffLines(a, b);
          expect(replay(edits, forNew: false), a);
          expect(replay(edits, forNew: true), b);
        }
      }
    });
  });

  group('formatUnified', () {
    test('identical files give an empty diff', () {
      expect(formatUnified(['a'], ['a']), '');
    });

    test('single change with context', () {
      final out = formatUnified(
        ['one', 'two', 'three', 'four'],
        ['one', 'TWO', 'three', 'four'],
        oldName: 'old.txt',
        newName: 'new.txt',
        context: 1,
      );
      expect(out, '--- old.txt\n+++ new.txt\n@@ -1,3 +1,3 @@\n one\n-two\n+TWO\n three\n');
    });

    test('distant changes split into separate hunks', () {
      final a = [for (var i = 1; i <= 20; i++) 'l$i'];
      final b = [...a]
        ..[1] = 'changed'
        ..[17] = 'altered';
      final hunks = buildHunks(diffLines(a, b), context: 2);
      expect(hunks.length, 2);
      expect(hunks.first.oldStart, 1);
      expect(hunks.last.oldStart, 16);
    });

    test('pure insertion into empty file uses zero start', () {
      final out = formatUnified([], ['a', 'b']);
      expect(out, contains('@@ -0,0 +1,2 @@'));
    });
  });

  group('applyPatch', () {
    String roundTrip(String a, String b) {
      final patch = formatUnified(splitLines(a), splitLines(b));
      return applyPatch(a, patch);
    }

    test('round trips a multi-hunk edit', () {
      final a = [for (var i = 1; i <= 30; i++) 'line $i'].join('\n') + '\n';
      final b = a
          .replaceFirst('line 3\n', 'three\n')
          .replaceFirst('line 25\n', '')
          .replaceFirst('line 30\n', 'line 30\nextra\n');
      expect(roundTrip(a, b), b);
    });

    test('round trips to and from empty', () {
      expect(roundTrip('', 'a\nb\n'), 'a\nb\n');
      expect(roundTrip('a\nb\n', ''), '');
    });

    test('rejects a patch that does not match', () {
      final patch = formatUnified(['a', 'b'], ['a', 'c']);
      expect(() => applyPatch('a\nz\n', patch), throwsA(isA<PatchException>()));
    });

    test('parses hunk headers without counts', () {
      final hunks = parseUnified('@@ -2 +2 @@\n-b\n+B\n');
      expect(hunks.single.oldStart, 2);
      expect(hunks.single.oldCount, 1);
      expect(applyPatch('a\nb\nc\n', '@@ -2 +2 @@\n-b\n+B\n'), 'a\nB\nc\n');
    });
  });
}

