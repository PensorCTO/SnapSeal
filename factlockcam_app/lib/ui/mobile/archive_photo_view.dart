import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/archive_item.dart';
import '../../data/models/sealed_asset.dart';
import '../../domain/services/vault_service.dart';

class ArchivePhotoView extends ConsumerStatefulWidget {
  const ArchivePhotoView({super.key, required this.item});

  final ArchiveItem item;

  @override
  ConsumerState<ArchivePhotoView> createState() => _ArchivePhotoViewState();
}

class _ArchivePhotoViewState extends ConsumerState<ArchivePhotoView> {
  late Future<SealedAsset> _sealedAssetFuture;

  @override
  void initState() {
    super.initState();
    _sealedAssetFuture = _loadSealedAsset();
  }

  @override
  void didUpdateWidget(covariant ArchivePhotoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.assetFingerprint != widget.item.assetFingerprint) {
      _sealedAssetFuture = _loadSealedAsset();
    }
  }

  Future<SealedAsset> _loadSealedAsset() {
    return ref
        .read(vaultServiceProvider)
        .extractForCourier(widget.item.assetFingerprint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.title ?? 'Photo')),
      backgroundColor: Colors.black,
      body: FutureBuilder<SealedAsset>(
        future: _sealedAssetFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final sealed = snapshot.data;
          if (sealed == null) {
            return const Center(
              child: Text(
                'Photo unavailable',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Image.memory(
                sealed.bytes,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Unable to decode sealed photo.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
