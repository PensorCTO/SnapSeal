import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/legal/disclaimers.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/di/service_providers.dart';
import 'acquisition_mode.dart';

/// Forensic HUD: sensor/resolution, UTC clock, live GPS, optional live hash.
///
/// Typography uses [AppTextStyles.monoSm] per forensic UI standards.
class TelemetryOverlay extends ConsumerStatefulWidget {
  const TelemetryOverlay({
    super.key,
    required this.acquisitionMode,
    required this.isRecording,
    this.archivingCount = 0,
    this.verifiedFlashTrigger = 0,
    this.previewWidth,
    this.previewHeight,
    this.latitude,
    this.longitude,
    this.liveHashHex,
  });

  final AcquisitionMode acquisitionMode;
  final bool isRecording;
  final int archivingCount;
  final int verifiedFlashTrigger;
  final int? previewWidth;
  final int? previewHeight;
  final double? latitude;
  final double? longitude;

  /// Lowercase hex SHA-256 (64 chars), no `0x` prefix.
  final String? liveHashHex;

  @override
  ConsumerState<TelemetryOverlay> createState() => _TelemetryOverlayState();
}

class _TelemetryOverlayState extends ConsumerState<TelemetryOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _clockTimer;
  Timer? _sealedTimer;
  late final AnimationController _blinkController;
  bool _showSealed = false;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _syncBlink();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant TelemetryOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldActive =
        oldWidget.isRecording || oldWidget.archivingCount > 0;
    final newActive = widget.isRecording || widget.archivingCount > 0;
    if (oldActive != newActive) {
      _syncBlink();
    }
    if (oldWidget.verifiedFlashTrigger != widget.verifiedFlashTrigger) {
      _showSealedGlyph();
    }
  }

  void _syncBlink() {
    final active = widget.isRecording || widget.archivingCount > 0;
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
    _sealedTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  void _showSealedGlyph() {
    _sealedTimer?.cancel();
    setState(() {
      _showSealed = true;
    });
    _sealedTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showSealed = false;
        });
      }
    });
  }

  TextStyle _mono() => AppTextStyles.monoSm();

  String _formatUtc(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi:$s UTC';
  }

  String _gpsLine() {
    if (widget.latitude != null && widget.longitude != null) {
      return 'GPS ${widget.latitude!.toStringAsFixed(6)}, '
          '${widget.longitude!.toStringAsFixed(6)}';
    }
    return 'GPS --.------, --.------';
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

    final previewLine =
        widget.previewWidth != null && widget.previewHeight != null
        ? '${widget.previewWidth}×${widget.previewHeight} · — Hz'
        : 'preview —×— · — Hz';

    final active = widget.isRecording || widget.archivingCount > 0;
    final quota = ref.watch(quotaStateProvider);
    final proofsLine = quota == null
        ? null
        : 'PROOFS: ${quota.proProofsRemaining}/${quota.proProofsBase}';

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 72),
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
                            child: Wrap(
                              spacing: 8,
                              children: [
                                Text(
                                  active ? '[REC]' : '[${_modeTag()}]',
                                  style: mono.copyWith(
                                    color: active
                                        ? AppColors.kineticGreen.withValues(
                                            alpha: 0.85,
                                          )
                                        : mono.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_showSealed)
                                  Text(
                                    '[ARCHIVED]',
                                    style: mono.copyWith(
                                      color: AppColors.verifiedNeon,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
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
                      Text(_gpsLine(), style: mono, textAlign: TextAlign.right),
                      Text(ts, style: mono, textAlign: TextAlign.right),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (proofsLine != null)
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  proofsLine,
                  style: mono.copyWith(
                    color: AppColors.starkWhite.withValues(alpha: 0.72),
                  ),
                ),
              ),
            if (proofsLine != null) const SizedBox(height: 2),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(_hashLine(), style: mono),
            ),
            const SizedBox(height: 4),
            Text(
              epistemicIntegrityShort,
              style: mono.copyWith(
                fontSize: 9,
                color: AppColors.starkWhite.withValues(alpha: 0.5),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
