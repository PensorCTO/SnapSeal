import 'dart:io';
import 'dart:typed_data';

import 'package:factlockcam/core/lock/locked_io_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lockedRenameEntry promotes full staging payload without truncating', () {
    final tempDir = Directory.systemTemp.createTempSync('factlockcam_rename_test_');
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final staging = File('${tempDir.path}/asset.seal.part');
    final finalPath = '${tempDir.path}/asset.seal';
    final payload = Uint8List.fromList(List<int>.generate(8192, (i) => i % 256));
    staging.writeAsBytesSync(payload, flush: true);

    lockedRenameEntry(
      LockedRenamePayload(stagingPath: staging.path, finalPath: finalPath),
    );

    final promoted = File(finalPath);
    expect(staging.existsSync(), isFalse);
    expect(promoted.existsSync(), isTrue);
    expect(promoted.lengthSync(), payload.length);
    expect(promoted.readAsBytesSync(), payload);
  });
}
