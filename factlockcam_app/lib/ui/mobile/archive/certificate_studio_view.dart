import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/di/service_providers.dart';
import '../../../core/ui/widgets/archive_panel_navigation_bar.dart';
import '../../../data/models/archive_item.dart';
import 'providers/asset_metadata_provider.dart';

/// Interactive certificate editor with live PDF preview and local metadata save.
class CertificateStudioView extends ConsumerStatefulWidget {
  const CertificateStudioView({super.key, required this.item});

  final ArchiveItem item;

  @override
  ConsumerState<CertificateStudioView> createState() =>
      _CertificateStudioViewState();
}

class _CertificateStudioViewState extends ConsumerState<CertificateStudioView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Timer? _debounce;
  int _previewGeneration = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.item.title ?? '';
    _descriptionController.text = widget.item.description ?? '';
    _titleController.addListener(_schedulePreviewAndSave);
    _descriptionController.addListener(_schedulePreviewAndSave);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(assetMetadataProvider(widget.item.assetFingerprint).notifier)
          .initFromArchiveItem(widget.item);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _schedulePreviewAndSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() => _previewGeneration++);
      unawaited(_saveMetadata());
    });
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

  Future<Uint8List> _buildCertificatePdf(PdfPageFormat format) async {
    final certService = ref.read(certificateExportServiceProvider);
    final storage = ref.read(localVaultStorageProvider);
    final resolved = await storage.resolveArchivePaths(widget.item);
    // Touch generation counter so PdfPreview rebuilds when metadata changes.
    assert(_previewGeneration >= 0);
    return certService.generateCertificatePdf(
      widget.item,
      titleOverride: _titleController.text,
      descriptionOverride: _descriptionController.text,
      thumbnailPath: resolved.thumbnailPath,
    );
  }

  Future<void> _printCertificate() async {
    await Printing.layoutPdf(onLayout: _buildCertificatePdf);
  }

  Future<void> _shareCertificate() async {
    await Printing.sharePdf(
      bytes: await _buildCertificatePdf(PdfPageFormat.letter),
      filename:
          'factlockcam_certificate_${widget.item.assetFingerprint.substring(0, 8)}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final metaState = ref.watch(
      assetMetadataProvider(widget.item.assetFingerprint),
    );

    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      appBar: ArchivePanelNavigationBar(
        title: 'Certificate Studio',
        onBack: () => Navigator.of(context).pop(),
        heroTag: 'certificate_studio_${widget.item.assetFingerprint}',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (metaState.saveError != null)
              Container(
                width: double.infinity,
                color: AppColors.alertAmber.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Save failed: ${metaState.saveError}',
                  style: AppTextStyles.monoSm(color: AppColors.alertAmber),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final landscape =
                      constraints.maxWidth > constraints.maxHeight;
                  final editor = _EditorPane(
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    isDirty: metaState.isDirty,
                  );
                  final preview = RepaintBoundary(
                    key: ValueKey<int>(_previewGeneration),
                    child: PdfPreview(
                      maxPageWidth: landscape ? 360 : 520,
                      scrollViewDecoration: BoxDecoration(
                        color: AppColors.titaniumPanel,
                        border: Border.all(
                          color: AppColors.verifiedNeon.withValues(alpha: 0.35),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      loadingWidget: const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                      onError: (context, error) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Preview failed: $error',
                            style: AppTextStyles.monoSm(
                              color: AppColors.alertAmber,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      build: _buildCertificatePdf,
                    ),
                  );

                  if (landscape) {
                    return Row(
                      children: [
                        Expanded(flex: 4, child: editor),
                        const SizedBox(width: 12),
                        Expanded(flex: 5, child: preview),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Expanded(flex: 2, child: editor),
                      const SizedBox(height: 12),
                      Expanded(flex: 3, child: preview),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => unawaited(_printCertificate()),
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: Text(
                        'PRINT',
                        style: AppTextStyles.monoSm(
                          color: AppColors.kineticGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.kineticGreen,
                        side: BorderSide(
                          color: AppColors.kineticGreen.withValues(alpha: 0.6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => unawaited(_shareCertificate()),
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: Text(
                        'SHARE PDF',
                        style: AppTextStyles.monoSm(
                          color: AppColors.starkWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.starkWhite,
                        side: BorderSide(
                          color: AppColors.starkWhite.withValues(alpha: 0.35),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorPane extends StatelessWidget {
  const _EditorPane({
    required this.titleController,
    required this.descriptionController,
    required this.isDirty,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final bool isDirty;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'METADATA',
                style: AppTextStyles.monoSm(
                  color: AppColors.starkWhite.withValues(alpha: 0.52),
                ),
              ),
              if (isDirty) ...[
                const SizedBox(width: 8),
                Text(
                  'SAVING…',
                  style: AppTextStyles.monoSm(color: AppColors.kineticGreen),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'TITLE',
            style: AppTextStyles.monoSm(
              color: AppColors.starkWhite.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: titleController,
            style: AppTextStyles.monoMd(color: AppColors.starkWhite),
            decoration: InputDecoration(
              hintText: 'Enter a title…',
              hintStyle: AppTextStyles.monoSm(
                color: AppColors.starkWhite.withValues(alpha: 0.35),
              ),
              filled: true,
              fillColor: AppColors.titaniumPanel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.starkWhite.withValues(alpha: 0.15),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.starkWhite.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.kineticGreen),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'DESCRIPTION',
            style: AppTextStyles.monoSm(
              color: AppColors.starkWhite.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: descriptionController,
            maxLines: 4,
            style: AppTextStyles.monoSm(
              color: AppColors.starkWhite,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: 'Enter a description…',
              hintStyle: AppTextStyles.monoSm(
                color: AppColors.starkWhite.withValues(alpha: 0.35),
              ),
              filled: true,
              fillColor: AppColors.titaniumPanel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.starkWhite.withValues(alpha: 0.15),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.starkWhite.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.kineticGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
