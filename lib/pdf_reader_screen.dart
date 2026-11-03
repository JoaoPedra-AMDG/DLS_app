import 'package:flutter/material.dart';
import 'models.dart';
import 'pdf_document_view.dart';
import 'platform_actions.dart' as platform;

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({
    super.key,
    required this.uri,
    required this.title,
    required this.filename,
    this.page = 1,
    this.onDownload,
  });
  final Uri uri;
  final String title, filename;
  final int page;
  final Future<bool> Function()? onDownload;
  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:
        expanded
            ? null
            : AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: 4,
              title: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 19),
                    label: const Text('Back', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final success =
                          await (widget.onDownload?.call() ??
                              platform.downloadPdf(
                                widget.uri,
                                widget.filename,
                              ));
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'The PDF could not download. Please try again.',
                            ),
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Check your connection and try the download again.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 19),
                  label: const Text('Download', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
              ],
              backgroundColor: Colors.white,
              foregroundColor: ink,
            ),
    body: SafeArea(
      child: PdfDocumentView(
        uri: widget.uri,
        title: widget.title,
        page: widget.page,
        onExpandedChanged: (value) => setState(() => expanded = value),
      ),
    ),
  );
}
