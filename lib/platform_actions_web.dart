import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('forRosaInstall')
external JSPromise<JSString> _install();

Future<String> installApp() async {
  try {
    return (await _install().toDart).toDart;
  } catch (_) {
    return 'manual';
  }
}

Future<bool> downloadPdf(Uri uri, String filename) async {
  final link =
      web.HTMLAnchorElement()
        ..href = uri.replace(fragment: '').toString()
        ..download = filename;
  web.document.body?.append(link);
  link.click();
  link.remove();
  return true;
}
