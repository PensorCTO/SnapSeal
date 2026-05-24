import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/haptic_service.dart';
import '../../../data/models/archive_item.dart';
import '../../../domain/blockchain/proof_state.dart';
import '../archive_item_actions.dart';
import '../../providers/proof_notarization_provider.dart';
import 'providers/thumbnail_cache_provider.dart';
import 'widgets/asset_securing_overlay.dart';

/// ListView slot height for chronology cards. Matches
/// `(itemHeight * (1 - overlapFraction)) + itemHeight` in
/// [UnifiedArchiveViewport].
const double kChronologyItemHeight = 340.0;
const double kChronologyOverlapFraction = 0.75;
const double kChronologyItemExtent =
    (kChronologyItemHeight * (1 - kChronologyOverlapFraction)) +
    kChronologyItemHeight;

/// Single asset plate in the chronology scroll view.
///
/// Wrapped in a [RepaintBoundary] at the root so that the expensive paint
/// operations (image decode, shadows transform) are isolated from the rest of
/// the widget tree. The card applies a horizontal [Transform.translate] and
/// [Transform.scale] that are directly bound to the scroll offset — no
/// [AnimationController] — creating a physical plate-stacking fanning effect
/// as items scroll away from the viewport center.
class ChronologyCard extends ConsumerStatefulWidget {
  const ChronologyCard({
    super.key,
    required this.item,
    required this.index,
    required this.scrollOffset,
    required this.viewportHeight,
    this.onTap,
  });

  /// The asset data backing this card.
  final ArchiveItem item;

  /// Zero-based position in the asset list.
  final int index;

  /// Current vertical scroll offset of the parent viewport.
  final double scrollOffset;

  /// Height of the viewport, used to compute center distance.
  final double viewportHeight;

  /// Called when the card is tapped to open the Asset Inspector.
  final VoidCallback? onTap;

  @override
  ConsumerState<ChronologyCard> createState() => _ChronologyCardState();
}

class _ChronologyCardState extends ConsumerState<ChronologyCard> {
  /// Distance in logical pixels from the viewport center to the card's own
  /// natural center, as of the last build.
  double _lastDistanceFromCenter = 0;

  @override
  Widget build(BuildContext context) {
    final cardBody = _buildCardBody();

    if (widget.viewportHeight <= 0) {
      return RepaintBoundary(child: cardBody);
    }

    // ── Scroll-driven calculations ──────────────────────────────────────
    // Scroll math uses the same slot stride as the ListView [itemExtent].
    const double itemSpacing = 20.0;
    const double totalStep = kChronologyItemHeight + itemSpacing;

    final cardCenter =
        totalStep * widget.index - widget.scrollOffset + kChronologyItemHeight / 2;
    final viewportCenter = widget.viewportHeight / 2;
    final distanceFromCenter = cardCenter - viewportCenter;
    _lastDistanceFromCenter = distanceFromCenter;

    // Normalised distance: 0 at centre, +/-1 at the viewport edges.
    final normalised =
        (distanceFromCenter / viewportCenter).clamp(-1.5, 1.5);

    // Scale/translate fan — opacity intentionally omitted so every card stays
    // fully legible while scrolling (no centre-only "spotlight" dimming).
    final scale = 1.0 - 0.25 * (normalised * normalised).clamp(0, 1);
    final rotationRad = math.pi / 90 * normalised.clamp(-1, 1);
    final translateX = 40.0 * normalised.clamp(-1, 1);

    _triggerCenterHaptic(distanceFromCenter);

    return RepaintBoundary(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(translateX, 0, 0, 1)
          ..rotateZ(rotationRad)
          ..scaleByDouble(scale, scale, scale, 1),
        child: cardBody,
      ),
    );
  }

  Widget _buildCardBody() {
    final thumbnailAsync = ref.watch(
      thumbnailCacheProvider(widget.item.assetFingerprint),
    );
    final proofStateAsync = AppConfig.usePolygonNotarizer
        ? ref.watch(
            proofNotarizationStateProvider(widget.item.assetFingerprint),
          )
        : null;
    final proofState = proofStateAsync?.value;
    final showPendingBadge = widget.item.pendingSync ||
        (AppConfig.usePolygonNotarizer &&
            proofState == ProofState.pendingNotarization);
    final pendingLabel = showPendingBadge
        ? (AppConfig.usePolygonNotarizer
              ? (proofState ?? ProofState.pendingNotarization).processingLabel
              : 'SYNC')
            .toUpperCase()
        : null;

    return AssetSecuringOverlay(
      assetFingerprint: widget.item.assetFingerprint,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: () {
          unawaited(
            ArchiveItemActions.showBottomSheet(
              context: context,
              ref: ref,
              item: widget.item,
            ),
          );
        },
        child: Container(
          height: kChronologyItemHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.titaniumHighlight,
                AppColors.titaniumPanel,
                Color(0xFF0A0A0A),
              ],
              stops: [0, 0.5, 1],
            ),
            border: Border.all(
              color: widget.item.pendingSync
                  ? AppColors.alertAmber.withValues(alpha: 0.55)
                  : AppColors.verifiedNeon.withValues(alpha: 0.55),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.verifiedNeon.withValues(alpha: 0.06),
                blurRadius: 14,
                spreadRadius: 0.3,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Hero(
                  tag: 'hero_thumb_${widget.item.assetFingerprint}',
                  child: thumbnailAsync.when(
                    data: (bytes) => bytes.isEmpty
                        ? _ThumbnailFallback(mimeType: widget.item.mimeType)
                        : Image.memory(
                            bytes,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _ThumbnailFallback(
                              mimeType: widget.item.mimeType,
                            ),
                          ),
                    error: (error, stackTrace) => _ThumbnailFallback(
                      mimeType: widget.item.mimeType,
                    ),
                    loading: () => _ThumbnailFallback(
                      mimeType: widget.item.mimeType,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0, 0.7],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 32, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.title ?? _shortHash(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.monoMd(
                          color: AppColors.starkWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatTimestamp(widget.item.createdAt)}  |  '
                        '${widget.item.mimeType ?? "unknown"}',
                        style: AppTextStyles.monoSm(
                          color: AppColors.starkWhite.withValues(alpha: 0.62),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatBytes(widget.item.byteLength),
                        style: AppTextStyles.monoSm(
                          color: AppColors.starkWhite.withValues(alpha: 0.48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showPendingBadge && pendingLabel != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.alertAmber.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      pendingLabel,
                      style: AppTextStyles.monoSm(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortHash() =>
      widget.item.assetFingerprint.length > 12
          ? widget.item.assetFingerprint.substring(0, 12)
          : widget.item.assetFingerprint;

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString();
    final mo = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$m';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _triggerCenterHaptic(double distanceFromCenter) {
    if (distanceFromCenter.abs() < 8.0 &&
        _lastDistanceFromCenter.abs() >= 8.0) {
      unawaited(ref.read(hapticServiceProvider).success());
    }
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback({required this.mimeType});

  final String? mimeType;

  @override
  Widget build(BuildContext context) {
    final isVideo = mimeType?.startsWith('video/') ?? false;
    return ColoredBox(
      color: AppColors.titaniumDeep,
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam_outlined : Icons.image_outlined,
          color: AppColors.starkWhite.withValues(alpha: 0.3),
          size: 40,
        ),
      ),
    );
  }
}
