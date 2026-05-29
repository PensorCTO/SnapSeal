import 'package:url_launcher/url_launcher.dart';

/// Opens remote compliance and support pages in the native in-app browser.
///
/// Content is served from Cloudflare Pages (Astro SSG) so copy can change
/// without an App Store binary update.
abstract final class ComplianceNavigation {
  static Future<void> openCompliancePage(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (!launched) {
      throw Exception('Could not launch $url');
    }
  }
}
