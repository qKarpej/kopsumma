import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

bool get canDownload => true;

Future<bool> downloadFile(List<int> bytes, String fileName, String mimeType) async {
  final blob = web.Blob(<JSAny>[Uint8List.fromList(bytes).toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return true;
}
