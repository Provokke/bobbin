<div align="center">

# bobbin

A line-based Myers diff, unified diff output and a patch applier for Dart, with a small command line tool. No packages beyond the SDK.

![License](https://img.shields.io/badge/LICENSE-MIT-blue?style=for-the-badge)  ![Language](https://img.shields.io/badge/DART-0175C2?style=for-the-badge&logo=dart&logoColor=white)  ![Tests](https://img.shields.io/badge/TESTS-12-brightgreen?style=for-the-badge)

Refer to [LICENSE](LICENSE) for the legal bits.

</div>

## What's in it

- `diffLines` computes a shortest edit script between two lists of lines using the Myers O(ND) algorithm. Each `Edit` is an equal, insert or delete of one line.
- `formatUnified` turns that script into unified diff text, with configurable context and merged hunks when changes sit close together.
- `applyPatch` parses unified diff text and applies it to the original content. It fails with a `PatchException` if any context or removed line doesn't match.
- `bobbin diff` and `bobbin patch`, a tiny CLI over the same functions.

```dart
import 'package:bobbin/bobbin.dart';

final diff = formatUnified(
  splitLines('one\ntwo\nthree\n'),
  splitLines('one\n2\nthree\n'),
  oldName: 'before.txt',
  newName: 'after.txt',
);
final restored = applyPatch('one\ntwo\nthree\n', diff);
```

## 🏗️ Architecture

```
 bin/bobbin.dart        CLI: diff [-U n] a b  |  patch file patch
        │
        ▼
 lib/bobbin.dart        exports the three files below
  ├─ src/myers.dart     EditKind, Edit, diffLines, splitLines
  │      forward search keeps a copy of v per step (trace), then walks back
  ├─ src/unified.dart   Hunk, buildHunks, formatUnified
  │      changed indexes -> ranges (gap <= 2 * context) -> hunks with line counts
  └─ src/patch.dart     PatchException, parseUnified, applyHunks, applyPatch
         hunk headers -> lines -> checked against the original, line by line
```

- `myers.dart` runs the greedy forward search, saving the frontier for every `d`, then backtracks through those copies to build the script. Memory grows with the square of the edit distance.
- `unified.dart` groups changed lines whose gap is at most twice the context size, prefix-sums the old and new line counts to get hunk headers, and writes `@@ -a,b +c,d @@` (dropping the count when it's 1).
- `patch.dart` accepts headers with or without counts, ignores `\ No newline` markers, and requires hunks in order with exact line numbers.
- `splitLines` splits on `\n` only and drops the empty tail after a final newline.

## 🚀 Quick start

```
dart pub get
dart test
```

From the command line:

```
dart run bobbin diff old.txt new.txt
dart run bobbin diff -U 5 old.txt new.txt > change.patch
dart run bobbin patch old.txt change.patch
```

`diff` exits with 1 when the files differ and 0 when they match. `patch` writes the patched text to standard output and doesn't touch the input file. With the two three-line files from the example:

```
--- a.txt
+++ b.txt
@@ -1,3 +1,3 @@
 one
-two
+2
 three
```

## 🧪 Testing

12 tests, all passing (`dart test`):

- `diffLines` (4): identical input is all equal, empty inputs, the classic Myers example comes out minimal, and a set of varied inputs where both sides can be rebuilt from the script.
- `formatUnified` (4): identical files give an empty diff, a single change with context, distant changes split into separate hunks, and a pure insertion into an empty file uses a zero start.
- `applyPatch` (4): a multi-hunk edit round trips, round trips to and from empty, a patch that doesn't match is rejected, and hunk headers without counts parse.

## ⚠️ Honest limits

- Among equally short scripts the choice is whatever the algorithm finds first, so it can differ from other diff tools.
- The patch applier needs exact line numbers. There's no search for shifted context and no fuzz.
- A final line with no trailing newline is treated like any other line.

## Licence

MIT.
