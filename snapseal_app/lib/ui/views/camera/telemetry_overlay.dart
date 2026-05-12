import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'acquisition_mode.dart';

/// Forensic HUD: sensor/resolution, UTC clock, GPS placeholder, optional live hash.
///
/// Typography uses [GoogleFonts.robotoMono] per forensic UI standards.
class TelemetryOverlay extends StatefulWidget {
  const TelemetryOverlay({
    super.key,
    required this.acquisitionMode,
    required this.isRecording,
    required this.isSealing,
    this.previewWidth,
    this.previewHeight,
    this.latitude,
    this.longitude,
    this.liveHashHex,
  });

  final AcquisitionMode acquisitionMode;
  final bool isRecording;
  final bool isSealing;
  final int? previewWidth;
  final int? previewHeight;
  final double? latitude;
  final double? longitude;

  /// Lowercase hex SHA-256 (64 chars), no `0x` prefix.
  final String? liveHashHex;

  @override
  State<TelemetryOverlay> createState() => _TelemetryOverlayState();
}

class _TelemetryOverlayState extends State<TelemetryOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _clockTimer;
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _syncBlink();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant TelemetryOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldActive = oldWidget.isRecording || oldWidget.isSealing;
    final newActive = widget.isRecording || widget.isSealing;
    if (oldActive != newActive) {
      _syncBlink();
    }
  }

  void _syncBlink() {
    final active = widget.isRecording || widget.isSealing;
    if (active) {
      _blinkController.repeat(reverse: true);
    } else {
      _blinkController
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  TextStyle _mono() => GoogleFonts.robotoMono(
        fontSize: 10.5,
        color: Colors.white.withValues(alpha: 0.8),
        height: 1.25,
      );

  String _formatUtc(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$y-$mo-$d $h:$mi:$s.$ms';
  }

  String _gpsLine() {
    if (widget.latitude != null && widget.longitude != null) {
      return 'GPS ${widget.latitude!.toStringAsFixed(4)}, '
          '${widget.longitude!.toStringAsFixed(4)}';
    }
    return 'GPS --.----, --.----';
  }

  String _hashLine() {
    final raw = widget.liveHashHex;
    if (raw == null || raw.length < 16) {
      return 'SHA256 live: —';
    }
    final clean = raw.toLowerCase();
    return 'SHA256 0x${clean.substring(0, 8)}...${clean.substring(clean.length - 8)}';
  }

  String _modeTag() {
    return switch (widget.acquisitionMode) {
      AcquisitionMode.photo => 'PHOTO',
      AcquisitionMode.video => 'VIDEO',
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final ts = _formatUtc(now);
    final mono = _mono();

    final previewLine = widget.previewWidth != null && widget.previewHeight != null
        ? '${widget.previewWidth}×${widget.previewHeight} · — Hz'
        : 'preview —×— · — Hz';

    final active = widget.isRecording || widget.isSealing;

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: _blinkController,
                        builder: (context, _) {
                          final t = active
                              ? 0.45 + 0.55 * _blinkController.value
                              : 1.0;
                          return Opacity(
                            opacity: t,
                            child: Text(
                              active ? '[REC]' : '[${_modeTag()}]',
                              style: mono.copyWith(
                                color: active
                                    ? const Color(0xFF00D26A)
                                        .withValues(alpha: 0.85)
                                    : mono.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                      Text(previewLine, style: mono),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _gpsLine(),
                        style: mono,
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        ts,
                        style: mono,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(_hashLine(), style: mono),
            ),
          ],
        ),
      ),
    );
  }
}
