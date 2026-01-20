import 'dart:io';

import 'package:bobbin/bobbin.dart';

const _usage = '''
Usage:
  bobbin diff [-U <context>] <old-file> <new-file>
  bobbin patch <file> <patch-file>

Exit status for diff is 0 when the files match and 1 when they differ.
''';

void main(List<String> args) {
  exitCode = _run(args);
}

int _run(List<String> args) {
  if (args.isEmpty) {
    stderr.write(_usage);
    return 2;
  }
  try {
    switch (args.first) {
      case 'diff':
        return _diff(args.sublist(1));
      case 'patch':
        return _patch(args.sublist(1));
      default:
        stderr.write(_usage);
        return 2;
    }
  } on FileSystemException catch (e) {
    stderr.writeln('bobbin: ${e.message}: ${e.path}');
    return 2;
  } on PatchException catch (e) {
    stderr.writeln('bobbin: ${e.message}');
    return 2;
  }
}

int _diff(List<String> args) {
  var context = 3;
  final files = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '-U' && i + 1 < args.length) {
      final value = int.tryParse(args[++i]);
      if (value == null || value < 0) {
        stderr.writeln('bobbin: invalid context length');
        return 2;
      }
      context = value;
    } else {
      files.add(args[i]);
    }
  }
  if (files.length != 2) {
    stderr.write(_usage);
    return 2;
  }
  final output = formatUnified(
    splitLines(File(files[0]).readAsStringSync()),
    splitLines(File(files[1]).readAsStringSync()),
    oldName: files[0],
    newName: files[1],
    context: context,
  );
  stdout.write(output);
  return output.isEmpty ? 0 : 1;
}

int _patch(List<String> args) {
  if (args.length != 2) {
    stderr.write(_usage);
    return 2;
  }
  final result = applyPatch(
    File(args[0]).readAsStringSync(),
    File(args[1]).readAsStringSync(),
  );
  stdout.write(result);
  return 0;
}

