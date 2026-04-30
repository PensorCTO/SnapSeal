import 'dart:typed_data';

class SealedAsset {
  const SealedAsset({required this.assetFingerprint, required this.bytes});

  final String assetFingerprint;
  final Uint8List bytes;
}
