import 'package:flutter/widgets.dart';

import 'acquisition_mode.dart';
import 'camera_view.dart';

Widget buildCapturePanel({
  required AcquisitionMode mode,
  required VoidCallback onBackToHub,
  Key? key,
}) {
  return CameraView(
    key: key,
    mode: mode,
    onBackToHub: onBackToHub,
  );
}
