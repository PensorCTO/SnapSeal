import 'package:flutter/widgets.dart';

import '../web/web_capture_disabled_panel.dart';

Widget buildSecureCommCapturePanel({required VoidCallback onBackToHub}) {
  return WebCaptureDisabledPanel(onBackToHub: onBackToHub);
}
