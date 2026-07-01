import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quicksave/core/utils/media_path.dart';

void main() {
  test('localMediaPathExists rejects content URIs', () {
    expect(localMediaPathExists('content://media/external/video/1'), isFalse);
    expect(localMediaPathExists(''), isFalse);
  });

  test('localMediaPathExists accepts existing files', () async {
    final file = File('${Directory.systemTemp.path}/qs_exists_test.bin');
    await file.writeAsBytes([1]);
    addTearDown(() => file.deleteSync());
    expect(localMediaPathExists(file.path), isTrue);
  });
}
