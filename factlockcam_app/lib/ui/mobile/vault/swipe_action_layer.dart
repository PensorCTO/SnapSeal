import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/archive_item.dart';

/// Wraps a [child] widget in a horizontal swipe gesture layer.
///
/// Right-swipe reveals a Kinetic Green background with a "Share/Courier"
/// action icon. Left-swipe reveals a white background with a "Verify Proof"
/// icon. When the swipe crosses the action threshold
/// [HapticFeedback.heavyImpact] fires.
class SwipeActionLayer extends StatefulWidget {
  const SwipeActionLayer({
    super.key,
    required this.child,
    required this.item,
    this.onShare,
    this.onVerify,
  });

  /// The card widget being wrapped (typically a [RepaintBoundary] containing
  /// [ChronologyCard]).
  final Widget child;

  /// The asset backing the card, used for action callbacks.
  final ArchiveItem item;

  /// Called when a right-swipe crosses the action threshold.
  final VoidCallback? onShare;

  /// Called when a left-swipe crosses the action threshold.
  final VoidCallback? onVerify;

  @override
  State<SwipeActionLayer> createState() => _SwipeActionLayerState();
}

class _SwipeActionLayerState extends State<SwipeActionLayer> {
  static const double _actionThreshold = 120.0;
  static const double _maxReveal = 200.0;

  double _dragOffset = 0;
  bool _heavyImpactFired = false;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final newOffset =
        (_dragOffset + details.delta.dx).clamp(-_maxReveal, _maxReveal);

    setState(() {
      _dragOffset = newOffset;
    });

    // Fire heavy haptic when crossing the action threshold.
    if (!_heavyImpactFired && _dragOffset.abs() >= _actionThreshold) {
      _heavyImpactFired = true;
      unawaited(HapticFeedback.heavyImpact());
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() >= _actionThreshold) {
      if (_dragOffset > 0 && widget.onShare != null) {
        widget.onShare!();
      } else if (_dragOffset < 0 && widget.onVerify != null) {
        widget.onVerify!();
      }
    }

    // Animate back to neutral with a spring-like feel.
    setState(() {
      _dragOffset = 0;
      _heavyImpactFired = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          // ── Background action layers ────────────────────────────────
          // Right-swipe: Kinetic Green with share icon
          if (_dragOffset > 0)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: AppColors.kineticGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _ActionLabel(
                  icon: Icons.send_outlined,
                  label: 'Share / Courier',
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
          // Left-swipe: white with verify icon
          if (_dragOffset < 0)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: AppColors.starkWhite,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _ActionLabel(
                  icon: Icons.verified_outlined,
                  label: 'Verify Proof',
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),

          // ── Draggable card ────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.identity()
              ..translateByDouble(_dragOffset, 0, 0, 1),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Action icon + label positioned left or right in the revealed background.
class _ActionLabel extends StatelessWidget {
  const _ActionLabel({
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.titaniumDeep),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.monoSm(
              color: AppColors.titaniumDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
