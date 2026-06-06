import 'package:flutter/material.dart';

import 'camera_chrome_frame.dart';

/// Normalized portrait viewport (9:16) inside the metallic chrome frame.
class SecureCommViewportFrame extends StatelessWidget {
  const SecureCommViewportFrame({
    super.key,
    required this.child,
    this.overlay,
  });

  final Widget child;
  final Widget? overlay;

  /// Cinema-safe guide used for Secure Comm video framing.
  static const double targetAspectRatio = 9 / 16;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = constraints.maxWidth;
        var height = width / targetAspectRatio;
        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * targetAspectRatio;
        }

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: CameraChromeFrame(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: child),
                  if (overlay != null) Positioned.fill(child: overlay!),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
