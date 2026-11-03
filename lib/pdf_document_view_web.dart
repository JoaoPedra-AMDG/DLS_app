import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class PdfDocumentView extends StatefulWidget {
  const PdfDocumentView({
    super.key,
    required this.uri,
    required this.title,
    this.page = 1,
    this.onExpandedChanged,
  });
  final Uri uri;
  final String title;
  final int page;
  final ValueChanged<bool>? onExpandedChanged;
  @override
  State<PdfDocumentView> createState() => _PdfDocumentViewState();
}

class _PdfDocumentViewState extends State<PdfDocumentView> {
  late final JSFunction _message;
  @override
  void initState() {
    super.initState();
    _message =
        ((web.MessageEvent event) {
          if (event.origin != Uri.base.origin || !event.data.isA<JSString>()) {
            return;
          }
          final message = (event.data as JSString).toDart;
          if (message == 'for-rosa-reader-expand') {
            widget.onExpandedChanged?.call(true);
          }
          if (message == 'for-rosa-reader-collapse') {
            widget.onExpandedChanged?.call(false);
          }
        }).toJS;
    web.window.addEventListener('message', _message);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _message);
    super.dispose();
  }

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
              'file': widget.uri.replace(fragment: '').toString(),
              'page': '${widget.page}',
              'title': widget.title,
              'embedded': '1',
            },
          );
      frame
        ..src = reader.toString()
        ..allowFullscreen = true
        ..allow = 'fullscreen'
        ..title = '${widget.title} — PDF reader'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0';
    },
  );
}
