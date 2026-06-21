/// No-op on non-web platforms.
Future<void> downloadTextFile({
  required String fileName,
  required String content,
  required String mimeType,
}) async {}
