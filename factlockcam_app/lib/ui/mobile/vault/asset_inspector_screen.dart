import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/ui/widgets/heavy_metal_backdrop.dart';
import '../../../data/models/archive_item.dart';
import '../../../data/models/sealed_asset.dart';
import '../../../domain/export/certificate_export_service.dart';
import '../../../domain/services/vault_service.dart';
import '../archive_item_actions.dart';
import '../archive_video_source.dart';
import 'providers/asset_metadata_provider.dart';
import 'providers/thumbnail_cache_provider.dart';

/// Full-screen detail view for a single sealed asset.
///
/// Displays the thumbnail via Hero transition, provides editable title
/// and description fields with optimistic metadata mutation via
/// [assetMetadataProvider], and presents an action matrix for Send Proof,
/// View/Play media, View Certificate, and Back to Dashboard.
class AssetInspectorScreen extends ConsumerStatefulWidget {
  const AssetInspectorScreen({
    super.key,
    required this.item,
  });

  final ArchiveItem item;

  @override
  ConsumerState<AssetInspectorScreen> createState() =>
      _AssetInspectorScreenState();
}

class _AssetInspectorScreenState extends ConsumerState<AssetInspectorScreen>
    with HeavyMetalBackdropMixin<AssetInspectorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // Sync controllers with provider state.
    _titleController.text = widget.item.title ?? '';
    _descriptionController.text = widget.item.description ?? '';

    // Save metadata when the user taps out of a field.
    _titleFocus.addListener(_onFocusChanged);
    _descriptionFocus.addListener(_onFocusChanged);

    // Defer provider modification to after the first frame — Riverpod 3.x
    // forbids state mutation during widget build/lifecycle methods.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(
        assetMetadataProvider(widget.item.assetFingerprint).notifier,
      );
      notifier.initFromArchiveItem(widget.item);
    });
  }

  @override
  void dispose() {
    _titleFocus.removeListener(_onFocusChanged);
    _descriptionFocus.removeListener(_onFocusChanged);
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_titleFocus.hasFocus && !_descriptionFocus.hasFocus) {
      _saveMetadata();
    }
  }

  Future<void> _saveMetadata() async {
    if (_saving) return;
    _saving = true;
    try {
      final notifier = ref.read(
        assetMetadataProvider(widget.item.assetFingerprint).notifier,
      );
      await notifier.setTitle(_titleController.text);
      await notifier.setDescription(_descriptionController.text);
      await notifier.save();
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final metaState = ref.watch(
      assetMetadataProvider(widget.item.assetFingerprint),
    );
    final thumbnailAsync = ref.watch(
      thumbnailCacheProvider(widget.item.assetFingerprint),
    );

    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: SafeArea(
        child: Column(
          children: [
            // ── Logo bar ─────────────────────────────
            HeavyMetalLogoBanner(
              actions: [
                if (metaState.isDirty)
                  IconButton(
                    tooltip: 'Save',
                    color: AppColors.kineticGreen,
                    onPressed: _saveMetadata,
                    icon: const Icon(Icons.save_outlined),
                  ),
                IconButton(
                  tooltip: 'Close',
                  color: AppColors.starkWhite,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            if (metaState.saveError != null)
              Container(
                width: double.infinity,
                color: AppColors.alertAmber.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.alertAmber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Save failed: ${metaState.saveError}',
                        style: AppTextStyles.monoSm(
                          color: AppColors.alertAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Scrollable body ─────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. Hero header ──────────────
                    _HeroImage(
                      tag: 'hero_thumb_${widget.item.assetFingerprint}',
                      thumbnailAsync: thumbnailAsync,
                      mimeType: widget.item.mimeType,
                    ),
                    const SizedBox(height: 20),

                    // ── 2. Metadata form ────────────
                    _MetadataField(
                      label: 'TITLE',
                      controller: _titleController,
                      focusNode: _titleFocus,
                      hint: 'Enter a title...',
                    ),
                    const SizedBox(height: 14),
                    _MetadataField(
                      label: 'DESCRIPTION',
                      controller: _descriptionController,
                      focusNode: _descriptionFocus,
                      hint: 'Enter a description...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // ── 3. Asset info strip ─────────
                    _InfoStrip(item: widget.item),
                    const SizedBox(height: 28),

                    // ── 4. Action matrix ────────────
                    Text(
                      'ACTIONS',
                      style: AppTextStyles.monoSm(
                        color: AppColors.starkWhite.withValues(alpha: 0.52),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ActionMatrix(onAction: _handleAction),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(InspectorAction action) {
    unawaited(ref.read(hapticServiceProvider).selectionClick());

    switch (action) {
      case InspectorAction.sendProof:
        _onSendProof();
      case InspectorAction.viewFull:
        _onViewFull();
      case InspectorAction.downloadMedia:
        _onDownloadMedia();
      case InspectorAction.viewCertificate:
        _onViewCertificate();
      case InspectorAction.delete:
        _onDelete();
      case InspectorAction.exit:
        Navigator.of(context).pop();
    }
  }

  void _onSendProof() {
    if (!mounted) return;
    unawaited(
      ArchiveItemActions.showSendProofDialog(
        context,
        ref,
        widget.item,
      ),
    );
  }

  void _onDownloadMedia() {
    if (!mounted || kIsWeb) return;
    unawaited(
      ArchiveItemActions.downloadMedia(context, ref, widget.item),
    );
  }

  Future<void> _onDelete() async {
    if (!mounted) return;
    await ArchiveItemActions.confirmAndDelete(context, ref, widget.item);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _onViewFull() async {
    final vault = ref.read(vaultServiceProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Decrypting asset...'),
        backgroundColor: AppColors.titaniumPanel,
      ),
    );

    try {
      final sealed = await vault.extractForCourier(
        widget.item.assetFingerprint,
      );

      if (!mounted) return;

      // Navigate to the asset-specific viewer.
      final isVideo = widget.item.mimeType?.startsWith('video/') ?? false;
      if (isVideo) {
        await _showFullscreenVideo(context, sealed);
      } else {
        await _showFullscreenImage(context, sealed);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Decryption failed: $e'),
          backgroundColor: AppColors.alertAmber,
        ),
      );
    }
  }

  Future<void> _showFullscreenImage(
    BuildContext context,
    SealedAsset sealed,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenImageViewer(bytes: sealed.bytes),
      ),
    );
  }

  Future<void> _showFullscreenVideo(
    BuildContext context,
    SealedAsset sealed,
  ) async {
    final extension = _extensionFromMime(widget.item.mimeType);
    final navigator = Navigator.of(context);
    final source = await createArchiveVideoSource(
      bytes: sealed.bytes,
      assetFingerprint: widget.item.assetFingerprint,
      extension: extension,
    );
    if (!mounted) {
      await source.dispose();
      return;
    }
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => _FullscreenVideoViewer(source: source),
      ),
    );
  }

  String _extensionFromMime(String? mimeType) {
    if (mimeType == null) return '.mp4';
    if (mimeType.contains('quicktime')) return '.mov';
    if (mimeType.contains('webm')) return '.webm';
    return '.mp4';
  }

  Future<void> _onViewCertificate() async {
    final certService = ref.read(certificateExportServiceProvider);
    final draft = await certService.buildCertificateDraft(widget.item);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.titaniumPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: AppColors.verifiedNeon.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        title: Text(
          'CERTIFICATE DRAFT',
          style: AppTextStyles.monoMd(color: AppColors.starkWhite),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            draft,
            style: AppTextStyles.monoSm(
              color: AppColors.starkWhite.withValues(alpha: 0.82),
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CLOSE',
              style: AppTextStyles.monoSm(color: AppColors.kineticGreen),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────

/// Hero-anchored header image.
class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.tag,
    required this.thumbnailAsync,
    required this.mimeType,
  });

  final String tag;
  final AsyncValue<Uint8List> thumbnailAsync;
  final String? mimeType;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
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
              color: AppColors.verifiedNeon.withValues(alpha: 0.4),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Hero(
            tag: tag,
            child: thumbnailAsync.when(
              data: (bytes) => bytes.isEmpty
                  ? _ThumbnailFallback(mimeType: mimeType)
                  : Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _ThumbnailFallback(mimeType: mimeType),
                    ),
              error: (error, stackTrace) => _ThumbnailFallback(mimeType: mimeType),
              loading: () => _ThumbnailFallback(mimeType: mimeType),
            ),
          ),
        ),
      ),
    );
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
          size: 48,
        ),
      ),
    );
  }
}

/// Single metadata text form field styled for the inspector.
class _MetadataField extends StatelessWidget {
  const _MetadataField({
    required this.label,
    required this.controller,
    required this.focusNode,
    this.hint,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.monoSm(
            color: AppColors.starkWhite.withValues(alpha: 0.52),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          style: AppTextStyles.monoMd(color: AppColors.starkWhite),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.monoMd(
              color: AppColors.starkWhite.withValues(alpha: 0.3),
            ),
            filled: true,
            fillColor: AppColors.titaniumDeep,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.titaniumEdge,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.titaniumEdge,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.kineticGreen.withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// Read-only information strip showing fingerprint, size, type, and timestamp.
class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.item});

  final ArchiveItem item;

  @override
  Widget build(BuildContext context) {
    final local = item.createdAt.toLocal();
    final ts =
        '${local.year}-${_p(local.month)}-${_p(local.day)} '
        '${_p(local.hour)}:${_p(local.minute)}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.titaniumDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.titaniumEdge,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('HASH', item.assetFingerprint.length > 20
              ? '${item.assetFingerprint.substring(0, 20)}...'
              : item.assetFingerprint),
          const SizedBox(height: 6),
          _infoRow('TYPE', item.mimeType ?? 'unknown'),
          const SizedBox(height: 6),
          _infoRow('SIZE', _fmtBytes(item.byteLength)),
          const SizedBox(height: 6),
          _infoRow('CAPTURED', ts),
          if (item.pendingSync) ...[
            const SizedBox(height: 6),
            _infoRow('SYNC', 'PENDING', color: AppColors.alertAmber),
          ],
        ],
      ),
    );
  }

  static String _p(int v) => v.toString().padLeft(2, '0');

  static String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTextStyles.monoSm(
              color: AppColors.starkWhite.withValues(alpha: 0.42),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.monoSm(
              color: color ?? AppColors.starkWhite.withValues(alpha: 0.82),
            ),
          ),
        ),
      ],
    );
  }
}

/// Action buttons at the bottom of the inspector.
enum InspectorAction {
  sendProof,
  viewFull,
  downloadMedia,
  viewCertificate,
  delete,
  exit,
}

class _ActionMatrix extends StatelessWidget {
  const _ActionMatrix({required this.onAction});

  final void Function(InspectorAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionTile(
          icon: Icons.send_outlined,
          label: 'SEND PROOF',
          subtitle: 'Generate a courier share link',
          onTap: () => onAction(InspectorAction.sendProof),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.visibility_outlined,
          label: 'VIEW/PLAY MEDIA',
          subtitle: 'Decrypt and view the original media',
          onTap: () => onAction(InspectorAction.viewFull),
        ),
        if (!kIsWeb) ...[
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.download_outlined,
            label: 'DOWNLOAD MEDIA',
            subtitle: 'Save an unencrypted copy via the share sheet',
            onTap: () => onAction(InspectorAction.downloadMedia),
          ),
        ],
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.shield_outlined,
          label: 'VIEW CERTIFICATE',
          subtitle: 'Tamper-evidence certificate draft',
          onTap: () => onAction(InspectorAction.viewCertificate),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.delete_outline,
          label: 'DELETE FROM DEVICE',
          subtitle: 'Remove this corrupted or unwanted archive item',
          accentColor: AppColors.alertAmber,
          onTap: () => onAction(InspectorAction.delete),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.exit_to_app_outlined,
          label: 'BACK TO DASHBOARD',
          subtitle: 'Return to the archive overview',
          onTap: () => onAction(InspectorAction.exit),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.titaniumHighlight,
            AppColors.titaniumPanel,
            Color(0xFF0A0A0A),
          ],
          stops: [0, 0.45, 1],
        ),
        border: Border.all(
          color: AppColors.verifiedNeon.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.verifiedNeon.withValues(alpha: 0.14),
          highlightColor: AppColors.verifiedNeon.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 24, color: accentColor ?? AppColors.verifiedNeon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.monoMd(color: AppColors.starkWhite),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.monoSm(
                          color: AppColors.starkWhite.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.starkWhite.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen image viewer for the decrypted original media.
class _FullscreenImageViewer extends StatefulWidget {
  const _FullscreenImageViewer({required this.bytes});

  final Uint8List bytes;

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  ui.Image? _decodedImage;
  Object? _decodeError;

  @override
  void initState() {
    super.initState();
    unawaited(_decodeBytes());
  }

  Future<void> _decodeBytes() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _decodedImage?.dispose();
        _decodedImage = frame.image;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _decodeError = error;
      });
    }
  }

  @override
  void dispose() {
    _decodedImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decoded = _decodedImage;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: decoded == null
            ? _decodeError == null
                ? const CircularProgressIndicator(color: Colors.white54)
                : Text(
                    'Unable to render image.',
                    style: AppTextStyles.monoSm(color: Colors.white70),
                  )
            : InteractiveViewer(
                child: RawImage(image: decoded, fit: BoxFit.contain),
              ),
      ),
    );
  }
}

/// Full-screen video player for the decrypted original media.
class _FullscreenVideoViewer extends StatefulWidget {
  const _FullscreenVideoViewer({required this.source});

  final ArchiveVideoSource source;

  @override
  State<_FullscreenVideoViewer> createState() => _FullscreenVideoViewerState();
}

class _FullscreenVideoViewerState extends State<_FullscreenVideoViewer> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.source.controller;
    _controller.play();
  }

  @override
  void dispose() {
    _controller.pause();
    unawaited(widget.source.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? InteractiveViewer(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio > 0
                      ? _controller.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(_controller),
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
