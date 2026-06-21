// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

Future<String?> pickJsonFileText() async {
  final input = html.FileUploadInputElement()
    ..accept = '.json,application/json';
  input.click();
  await input.onChange.first;
  final file = input.files?.first;
  if (file == null) return null;

  final reader = html.FileReader();
  final completer = Completer<String?>();
  reader.onLoad.listen((_) {
    final result = reader.result;
    completer.complete(result is String ? result : null);
  });
  reader.onError.listen((_) => completer.complete(null));
  reader.readAsText(file);
  return completer.future;
}
