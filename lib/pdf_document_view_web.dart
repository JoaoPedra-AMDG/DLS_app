import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class PdfDocumentView extends StatelessWidget {
  const PdfDocumentView({
    super.key,
    required this.uri,
    required this.title,
    this.page = 1,
  });
  final Uri uri;
  final String title;
  final int page;
  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (element) {
      final frame = element as web.HTMLIFrameElement;
      final reader = Uri.base
          .replace(fragment: '', query: '')
          .resolve('reader.html')
          .replace(
            queryParameters: {
              'file': uri.replace(fragment: '').toString(),
              'page': '$page',
              'title': title,
              'embedded': '1',
            },
          );
      frame
        ..src = reader.toString()
        ..title = '$title — PDF reader'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0';
    },
  );
}
