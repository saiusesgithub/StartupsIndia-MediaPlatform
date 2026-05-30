import 'package:url_launcher/url_launcher.dart';

class AppUrls {
  static final Uri events = Uri.parse('https://www.startupsindia.in/events');
  static final Uri programs = Uri.parse(
    'https://www.startupsindia.in/programs',
  );
  static final Uri privacy = Uri.parse('https://www.startupsindia.in/privacy');
  static final Uri deleteAccount = Uri.parse(
    'https://www.startupsindia.in/delete-account',
  );
  static final Uri terms = Uri.parse('https://www.startupsindia.in/terms');
}

Future<void> launchExternalUrl(Uri uri) async {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
