import 'package:flutter/material.dart';

class ArchiveThumbnail extends StatelessWidget {
  const ArchiveThumbnail({
    super.key,
    required this.thumbnailPath,
    required this.showVideoBadge,
  });

  final String thumbnailPath;
  final bool showVideoBadge;

  @override
  Widget build(BuildContext context) {
    return ArchiveThumbnailFallback(showVideoBadge: showVideoBadge);
  }
}

class ArchiveThumbnailFallback extends StatelessWidget {
  const ArchiveThumbnailFallback({super.key, required this.showVideoBadge});

  final bool showVideoBadge;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black26,
      child: Icon(
        showVideoBadge
            ? Icons.videocam_outlined
            : Icons.image_not_supported_outlined,
        color: Colors.white70,
      ),
    );
  }
}
