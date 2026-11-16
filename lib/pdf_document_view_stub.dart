import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Widget build(BuildContext context) => Center(
    child: FilledButton.icon(
      onPressed:
          () => launchUrl(
            uri.replace(fragment: 'page=$page'),
            mode: LaunchMode.externalApplication,
          ),
      icon: const Icon(Icons.open_in_browser),
      label: const Text('Open PDF in your browser'),
    ),
  );
}
