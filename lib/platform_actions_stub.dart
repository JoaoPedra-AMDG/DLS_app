import 'package:url_launcher/url_launcher.dart';

Future<String> installApp() async => 'manual';
Future<bool> downloadPdf(Uri uri, String filename) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
