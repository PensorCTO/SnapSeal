import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

const _rollChars = '0123456789abcdefABCDEF';

/// Rapid alphanumeric roll that snaps to [targetHash] after [duration].
class HashCascadeTicker extends StatefulWidget {
  const HashCascadeTicker({
    super.key,
    required this.targetHash,
    this.duration = const Duration(milliseconds: 1500),
  });

  final String targetHash;
  final Duration duration;

  @override
  State<HashCascadeTicker> createState() => _HashCascadeTickerState();
}

class _HashCascadeTickerState extends State<HashCascadeTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _random = Random();
  late List<String> _displayChars;
  late List<String> _targetChars;

  @override
  void initState() {
    super.initState();
    _targetChars = _normalizeHash(widget.targetHash);
    _displayChars = List<String>.generate(
      _targetChars.length,
      (_) => _rollChars[_random.nextInt(_rollChars.length)],
    );
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_onTick)
      ..forward();
  }

  @override
  void didUpdateWidget(covariant HashCascadeTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetHash != widget.targetHash) {
      _targetChars = _normalizeHash(widget.targetHash);
      _displayChars = List<String>.generate(
        _targetChars.length,
        (_) => _rollChars[_random.nextInt(_rollChars.length)],
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  List<String> _normalizeHash(String hash) {
    final normalized = hash.trim().toLowerCase();
    if (normalized.isEmpty) {
      return List<String>.filled(64, '0');
    }
    return normalized.split('');
  }

  void _onTick() {
    final t = _controller.value;
    final lockStart = 0.82;
    setState(() {
      for (var i = 0; i < _targetChars.length; i++) {
        if (t >= lockStart) {
          _displayChars[i] = _targetChars[i];
        } else {
          final charProgress = (t * _targetChars.length - i).clamp(0.0, 1.0);
          if (charProgress > 0.65) {
            _displayChars[i] = _targetChars[i];
          } else if (charProgress > 0.0) {
            _displayChars[i] = _rollChars[_random.nextInt(_rollChars.length)];
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = _displayChars.join();
    final glowAlpha = 0.35 + (_controller.value * 0.25);

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.titaniumPanel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.verifiedNeon.withValues(alpha: glowAlpha),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.verifiedNeon.withValues(alpha: glowAlpha * 0.35),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ALIGNING DIGITAL DNA',
                style: AppTextStyles.monoSm(
                  color: AppColors.kineticGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                display,
                style: AppTextStyles.monoMd(
                  color: _controller.value >= 0.82
                      ? AppColors.verifiedNeon
                      : AppColors.kineticGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _controller.value >= 0.82 ? 'HASH LOCKED' : 'VERIFYING…',
                style: AppTextStyles.monoSm(
                  color: AppColors.starkWhite.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
