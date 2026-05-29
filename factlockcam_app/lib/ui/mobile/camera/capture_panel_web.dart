import 'package:flutter/widgets.dart';

import '../../web/web_capture_disabled_panel.dart';
import 'acquisition_mode.dart';

Widget buildCapturePanel({
  required AcquisitionMode mode,
  required VoidCallback onBackToHub,
  Key? key,
}) {
  return WebCaptureDisabledPanel(
    key: key,
    onBackToHub: onBackToHub,
  );
}
