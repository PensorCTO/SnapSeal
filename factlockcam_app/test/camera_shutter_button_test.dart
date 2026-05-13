import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapseal/ui/views/camera/camera_view.dart';

void main() {
  testWidgets('video shutter tap starts recording when idle', (tester) async {
    var pressCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CameraShutterButton(
              enabled: true,
              isVideo: true,
              isRecording: false,
              onPressed: () async {
                pressCount += 1;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CameraShutterButton));
    await tester.pump();

    expect(pressCount, 1);
  });

  testWidgets('video shutter tap stops recording when active', (tester) async {
    var pressCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CameraShutterButton(
              enabled: true,
              isVideo: true,
              isRecording: true,
              onPressed: () async {
                pressCount += 1;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CameraShutterButton));
    await tester.pump();

    expect(pressCount, 1);
  });

  testWidgets('photo shutter tap captures once', (tester) async {
    var pressCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CameraShutterButton(
              enabled: true,
              isVideo: false,
              isRecording: false,
              onPressed: () async {
                pressCount += 1;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CameraShutterButton));
    await tester.pump();

    expect(pressCount, 1);
  });
}
