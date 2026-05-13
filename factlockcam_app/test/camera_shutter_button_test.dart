import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:factlockcam/core/ui/painters/shutter_button_painter.dart';
import 'package:factlockcam/ui/views/camera/camera_view.dart';

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

  test('ShutterIrisPainter repaints when close progress changes', () {
    const open = ShutterIrisPainter(
      closeProgress: 0,
      recordFill: 0,
      verifiedFlash: 0,
    );
    const closed = ShutterIrisPainter(
      closeProgress: 0.6,
      recordFill: 0,
      verifiedFlash: 0,
    );

    expect(closed.closeProgress, greaterThan(0));
    expect(closed.shouldRepaint(open), isTrue);
  });

  testWidgets('recording shutter shows kinetic record fill', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CameraShutterButton(
              enabled: true,
              isVideo: true,
              isRecording: true,
              onPressed: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final customPaint = tester.widget<CustomPaint>(_shutterPaintFinder());
    final painter = customPaint.painter! as ShutterIrisPainter;
    expect(painter.recordFill, greaterThan(0));
  });
}

Finder _shutterPaintFinder() {
  return find.descendant(
    of: find.byType(CameraShutterButton),
    matching: find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is ShutterIrisPainter,
    ),
  );
}
